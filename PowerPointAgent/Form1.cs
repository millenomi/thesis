using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using Microsoft.Office.Core;
using Ppt = Microsoft.Office.Interop.PowerPoint;
using System.Media;
using System.IO;

using Newtonsoft.Json;

namespace PowerPointAgent
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        class PositionedSlidePoint : IComparable<PositionedSlidePoint>
        {
            public float Position { get; set; }
            public SlidePoint Point { get; set; }

            public static List<SlidePoint> OrderedPointsFromGroups(List<List<PositionedSlidePoint>> groups)
            {
                var result = new List<SlidePoint>();

                foreach (List<PositionedSlidePoint> group in groups)
                {
                    var sorted = new List<PositionedSlidePoint>(group);
                    sorted.Sort();

                    foreach (PositionedSlidePoint sp in sorted)
                        result.Add(sp.Point);
                }

                return result;
            }

            public int CompareTo(PositionedSlidePoint other)
            {
                return this.Position.CompareTo(other.Position);
            }
        }

        private void AddPointsFromShape(Ppt.Shape shape, List<List<PositionedSlidePoint>> pointGroups)
        {
            bool isGroup = false;
            try
            {
                isGroup = shape.GroupItems.Count > 0;
            }
            catch (Exception)
            {
                // Evidently not a group
            }

            if (isGroup)
            {
                foreach (Ppt.Shape sub in shape.GroupItems)
                    AddPointsFromShape(sub, pointGroups);
            }
            else
            {
                TextRange2 paragraphs;
                try
                {
                    paragraphs = shape.TextFrame2.TextRange.get_Paragraphs();
                }
                catch (Exception)
                {
                    // Evidently has no paragraphs
                    return;
                }


                var points = new List<PositionedSlidePoint>();

                foreach (TextRange2 para in paragraphs)
                {
                    if (para.Text.Trim().Equals(""))
                        continue;

                    var point = new SlidePoint() { Text = para.Text.Replace("\r", "").Replace("\v", "\n"), Indentation = para.ParagraphFormat.IndentLevel - 1 };
                    points.Add(new PositionedSlidePoint() { Position = para.BoundTop, Point = point });
                }

                pointGroups.Add(points);
            }
        }

        private void button1_Click(object sender, EventArgs e)
        {
            Ppt.Application app = new Ppt.Application();
            Ppt.Presentation p = app.ActivePresentation;

            string title = p.Name;

            if (title.ToLowerInvariant().EndsWith(".ppt"))
                title = title.Substring(0, title.Length - 4);

            var slides = new List<Slide>();

            var desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
            var images = Path.Combine(desktop, "ResultImages");

            if (!Directory.Exists(images))
                Directory.CreateDirectory(images);

            int i = 0;

            foreach (Ppt.Slide s in p.Slides)
            {
                var groups = new List<List<PositionedSlidePoint>>();
                foreach (Ppt.Shape shape in s.Shapes)
                    AddPointsFromShape(shape, groups);

                Slide slide = new Slide() { Points = PositionedSlidePoint.OrderedPointsFromGroups(groups) };
                slides.Add(slide);

                var imageFile = Path.Combine(images, "Slide." + i + ".png");
                if (File.Exists(imageFile))
                    File.Delete(imageFile);

                s.Export(imageFile, "png");

                i++;
            }

            Presentation jsonp = new Presentation() { Title = title, Slides = slides };

            string json = JsonConvert.SerializeObject(jsonp);

            var jsonPath = Path.Combine(desktop, "Result.json");

            using (var f = new FileStream(jsonPath, FileMode.Create))
            {
                byte[] bytes = Encoding.UTF8.GetBytes(json);
                f.Write(bytes, 0, bytes.Length);
            }
            System.Diagnostics.Debug.WriteLine(json);
        }
    }


    [JsonObject]
    class Slide
    {
        [JsonProperty(PropertyName = "points")]
        public List<SlidePoint> Points { get; set; }
    }

    [JsonObject]
    class SlidePoint
    {
        [JsonProperty(PropertyName = "text")]
        public string Text { get; set; }

        [JsonProperty(PropertyName = "indentation")]
        public int Indentation { get; set; }
    }

    [JsonObject]
    class Presentation
    {
        [JsonProperty(PropertyName = "title")]
        public string Title { get; set; }

        [JsonProperty(PropertyName = "slides")]
        public List<Slide> Slides { get; set; }
    }
}
