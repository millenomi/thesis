//
//  JSSchema.m
//  Subject
//
//  Created by ∞ on 22/10/10.
//  Copyright 2010 Emanuele Vulcano (Infinite Labs). All rights reserved.
//

#import "SJSchema.h"
#import <objc/runtime.h>
#import "SJEndpoint.h"

CF_INLINE NSString* SJStringByUppercasingFirstLetter(NSString* x) {
	return [[[x substringToIndex:1] uppercaseString] stringByAppendingString:[x substringFromIndex:1]];
}

@interface SJSchema ()

- (id) validatedValueForValue:(id)value validClass:(Class)cls validArrayValueClass:(Class)arrayValueCls validDictionaryValueClass:(Class)dictionaryValueCls error:(NSError**) e;

- (id) valueForCallingSelector;

@end


@implementation SJSchema

+ (NSDictionary*) classDynamicPropertyGettersByProperty;
{
	if (self == [SJSchema class])
		return [NSDictionary dictionary];
	
	unsigned int propCount;
	objc_property_t* props = class_copyPropertyList(self, &propCount);
	
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	
	unsigned int i; for (i = 0; i < propCount; i++) {
		
		const char* name = property_getName(props[i]);
		NSString* propertyName = [NSString stringWithUTF8String:name];
		
		const char* attrs = property_getAttributes(props[i]);

		NSArray* attributes = [[NSString stringWithUTF8String:attrs] componentsSeparatedByString:@","];
		
		// If the property is @dynamic...
		if ([attributes containsObject:@"D"]) {

			NSString* getterName = nil;
			
			for (NSString* attribute in attributes) {
				if ([attribute hasPrefix:@"G"]) {
					getterName = [attribute substringFromIndex:1];
					break;
				}
			}
			
			if (!getterName)
				getterName = propertyName;
			
			[dict setObject:getterName forKey:propertyName];
		}
		
	}
	
	if (props)
		free(props);
	
	return dict;
}

- (id) initWithJSONDictionaryValue:(id) value error:(NSError**) e;
{
	if ((self = [super init])) {
		if (![value isKindOfClass:[NSDictionary class]]) {
			if (e) *e = [NSError errorWithDomain:kSJSchemaErrorDomain code:kSJSchemaErrorInitValueNotADictionary userInfo:nil];
			[self release];
			return nil;
		}
		
		NSMutableDictionary* finalValues = [NSMutableDictionary dictionary];
		NSMutableSet* unspecifieds = [NSMutableSet set];
		
		// TODO subclassing, if useful.
		NSDictionary* properties = [[self class] classDynamicPropertyGettersByProperty];
		
		for (NSString* prop in properties) {
			
			// We use getter names as the JSON dictionary keys to look up.
			NSString* getter = [properties objectForKey:prop];
			id subvalue = [value objectForKey:getter];
			
			NSString* uppercasePropName = SJStringByUppercasingFirstLetter(prop);

			if (!subvalue) {
				BOOL optional = NO;
				
				SEL isValueOptionalSelector = NSSelectorFromString([NSString stringWithFormat:@"isValueOptionalFor%@Key", uppercasePropName]);
				
				if ([self respondsToSelector:isValueOptionalSelector]) {
					NSMethodSignature* sig = [self methodSignatureForSelector:isValueOptionalSelector];
					NSInvocation* invo = [NSInvocation invocationWithMethodSignature:sig];
					
					[invo setTarget:self];
					[invo setSelector:isValueOptionalSelector];
					[invo invoke];
					
					[invo getReturnValue:&optional];
				}
				
				if (!optional) {
					if (e) *e = [NSError errorWithDomain:kSJSchemaErrorDomain code:kSJSchemaErrorRequiredValueMissing userInfo:[NSDictionary dictionaryWithObject:prop forKey:kSJSchemaErrorSourceKey]];
					[self release];
					return nil;
				} else {
					[unspecifieds addObject:getter];
					continue;
				}
			}
			
			
			Class validClass = Nil, validArrayValueClass = Nil, validDictionaryValueClass = Nil;
			
			SEL validToOneClassSelector = NSSelectorFromString([NSString stringWithFormat:@"validClassFor%@Key", uppercasePropName]);
						
			SEL validValueClassForArraySelector = NSSelectorFromString([NSString stringWithFormat:@"validClassForValuesOf%@ArrayKey", uppercasePropName]);

			SEL validValueClassForDictSelector = NSSelectorFromString([NSString stringWithFormat:@"validClassForValuesOf%@DictionaryKey", uppercasePropName]);

			if ([self respondsToSelector:validValueClassForDictSelector]) {
				validClass = [NSDictionary class];
				validDictionaryValueClass = [self performSelector:validValueClassForDictSelector];
			} else if ([self respondsToSelector:validValueClassForArraySelector]) {
				validClass = [NSArray class];
				validArrayValueClass = [self performSelector:validValueClassForArraySelector];
			} else
				validClass = [self performSelector:validToOneClassSelector];
			
			if (!validClass) {
				[self release];
				[NSException raise:@"SJSchemaUnknownPropertyType" format:@"You MUST implement one of %@, %@, or %@ in class %@ to specify the type of property %@",
					[NSString stringWithFormat:@"validClassFor%@Key", uppercasePropName],
					[NSString stringWithFormat:@"validClassForValuesOf%@ArrayKey", uppercasePropName],
					[NSString stringWithFormat:@"validClassForValuesOf%@DictionaryKey", uppercasePropName],
					[self class],
					prop];
				return nil;
			}
			
			NSError* e2;
			id validatedSubvalue = [self validatedValueForValue:subvalue validClass:validClass validArrayValueClass:validArrayValueClass validDictionaryValueClass:validDictionaryValueClass error:&e2];
			
			if (!validatedSubvalue) {
				NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										  prop, kSJSchemaErrorSourceKey,
										  e2, NSUnderlyingErrorKey,
										  nil];
				if (e) *e = [NSError errorWithDomain:kSJSchemaErrorDomain code:kSJSchemaErrorNoValidValueForProperty userInfo:userInfo];
				
				[self release];
				return nil;
			} else
				[finalValues setObject:validatedSubvalue forKey:getter];
			
		}
		
		if (![self validateAndReturnError:e]) {
			[self release];
			return nil;
		}
		
		values = [finalValues copy];
		unspecifiedOptionalValues = [unspecifieds copy];
	}
	
	return self;
}

- (void) dealloc
{
	[values release];
	[unspecifiedOptionalValues release];
	[super dealloc];
}


- (id) validatedValueForValue:(id)value validClass:(Class)cls validArrayValueClass:(Class)arrayValueCls validDictionaryValueClass:(Class)dictionaryValueCls error:(NSError**) e;
{
	
	if (![cls isSubclassOfClass:[SJSchema class]]) {

		if (![value isKindOfClass:cls]) {
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:value forKey:kSJSchemaErrorInvalidObjectKey];
			if (e) *e = [NSError errorWithDomain:kSJSchemaErrorDomain code:kSJSchemaErrorValueFailedValidation userInfo:userInfo];
			return nil;
		}
		
		if (arrayValueCls) {
			
			if (![value isKindOfClass:[NSArray class]]) {
				NSDictionary* userInfo = [NSDictionary dictionaryWithObject:value forKey:kSJSchemaErrorInvalidObjectKey];
				if (e) *e = [NSError errorWithDomain:kSJSchemaErrorDomain code:kSJSchemaErrorValueFailedValidation userInfo:userInfo];
				return nil;
			}
			
			NSMutableArray* arr = [NSMutableArray array];
			
			NSInteger i = 0;
			
			for (id x in value) {
				NSError* e2;
				id v = [self validatedValueForValue:x validClass:arrayValueCls validArrayValueClass:nil validDictionaryValueClass:nil error:&e2];

				if (!v) {
					if (e) {
						NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											  [NSNumber numberWithInteger:i], kSJSchemaErrorSourceKey,
											  value, kSJSchemaErrorInvalidObjectKey,
											  e2, NSUnderlyingErrorKey,
											  nil];
						*e = [NSError errorWithDomain:kSJSchemaErrorDomain code:kSJSchemaErrorArrayValueFailedValidation userInfo:userInfo];
					}
					
					return nil;
				}
				
				[arr addObject:v];
			}
			
			return arr;
			
		} else if (dictionaryValueCls) {
			
			if (![value isKindOfClass:[NSDictionary class]]) {
				NSDictionary* userInfo = [NSDictionary dictionaryWithObject:value forKey:kSJSchemaErrorInvalidObjectKey];
				if (e) *e = [NSError errorWithDomain:kSJSchemaErrorDomain code:kSJSchemaErrorValueFailedValidation userInfo:userInfo];
				return nil;
			}
			
			NSMutableDictionary* dict = [NSMutableDictionary dictionary];
			
			for (id x in value) {
				id preV = [value objectForKey:x];
				NSError* e2;
				id v = [self validatedValueForValue:preV validClass:dictionaryValueCls validArrayValueClass:nil validDictionaryValueClass:nil error:&e2];

				if (!v) {
					if (e) {
						NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
												  x, kSJSchemaErrorSourceKey,
												  preV, kSJSchemaErrorInvalidObjectKey,
												  e2, NSUnderlyingErrorKey,
												  nil];
						*e = [NSError errorWithDomain:kSJSchemaErrorDomain code:kSJSchemaErrorDictionaryValueFailedValidation userInfo:userInfo];
					}
					
					return nil;
				}
				
				[dict setObject:v forKey:x];
			}
			
			return dict;
			
		} else
			return value;
		
	} else
		return [[[cls alloc] initWithJSONDictionaryValue:value error:e] autorelease];
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)aSelector;
{
	NSString* prop = NSStringFromSelector(aSelector);
	if ([values objectForKey:prop] || [unspecifiedOptionalValues containsObject:prop])
		return [super methodSignatureForSelector:@selector(valueForCallingSelector)];
	else
		return [super methodSignatureForSelector:aSelector];
}

- (id) valueForCallingSelector;
{ /* used for its signature only */ return nil; }

- (void) forwardInvocation:(NSInvocation *)anInvocation;
{
	NSString* prop = NSStringFromSelector([anInvocation selector]);
	id x = [values objectForKey:prop];
	
	if (x)
		[anInvocation setReturnValue:&x];
	else if ([unspecifiedOptionalValues containsObject:prop]) {
		id nilVar = nil;
		[anInvocation setReturnValue:&nilVar];
	} else
		[self doesNotRecognizeSelector:[anInvocation selector]];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ (missing = %@, values = %@)", [super description], unspecifiedOptionalValues, values];
}

- (NSUInteger) hash;
{
	return [values hash] ^ [unspecifiedOptionalValues hash] ^ [[self class] hash];
}

- (BOOL) isEqual:(id)object;
{
	return object == self || ([object isKindOfClass:[self class]] && [[object underlyingSpecifiedSchemaValues] isEqual:values] && [[object underlyingMissingOptionalValueKeys] isEqual:unspecifiedOptionalValues]);
}

- (NSDictionary *) underlyingSpecifiedSchemaValues;
{
	return values;
}

- (NSSet *) underlyingMissingOptionalValueKeys;
{
	return unspecifiedOptionalValues;
}

- (BOOL) validateAndReturnError:(NSError**) e;
{
	return YES;
}

@end


@implementation SJSchema (SJLiveLoading)

+ (void) contentsOfURL:(id) stringOrURL ofEndpoint:(SJEndpoint*) endpoint completionHandler:(void (^)(id s)) completion failureHandler:(void (^)(NSError* e)) failure;
{
	[endpoint beginDownloadingFromURL:stringOrURL completionHandler:^(id <SJRequest> req) {
		
		if (req.error) {
			if (failure)
				failure(req.error);
			return;
		}
		
		if (!req.JSONValue) {
			if (failure)
				failure(nil); // TODO appropriate error
			return;
		}
		
		NSError* e;
		id x = [[[self alloc] initWithJSONDictionaryValue:req.JSONValue error:&e] autorelease];
		if (x && completion)
			completion(x);
		else if (!x && failure)
			failure(e);
	}];
}

@end
