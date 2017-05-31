using Gee;
using Engine;

public abstract class RenderScene {}

public class RenderScene3D : RenderScene
{
    private bool copy_state;

    public RenderScene3D(bool copy_state, Size2i screen_size, float scene_aspect_ratio, Rectangle rect)
    {
        this.copy_state = copy_state;
        this.rect = rect;
        this.screen_size = screen_size;

        queue = new RenderQueue3D();
        lights = new ArrayList<LightSource>();

        Vec3 scene_translation = Vec3
        (
            (rect.x + rect.width ) / screen_size.width  - 1,
            (rect.y + rect.height) / screen_size.height - 1,
            0
        );
        Vec3 scene_scale = Vec3
        (
            rect.width / screen_size.width,
            rect.height / screen_size.height,
            1
        );

        scene_matrix = Calculations.translation_matrix(scene_translation).mul_mat(Calculations.scale_matrix(scene_scale));
        set_camera(new Camera());
    }

    public void add_object(Transformable3D object)
    {
        arrange_transformable(copy_state ? object.copy() : object);
    }

    public void add_light_source(LightSource light)
    {
        _lights.add(copy_state ? light.copy() : light);
    }

    public void set_camera(Camera camera)
    {
        view_matrix = camera.get_view_transform().get_full_matrix();
        view_angle = camera.view_angle;
    }

    private void arrange_transformable(Transformable3D obj)
    {
        if (obj is RenderGeometry3D)
            foreach (Transformable3D o in (obj as RenderGeometry3D).geometry)
                arrange_transformable(o);
        else if (obj is RenderObject3D)
            arrange_object(obj as RenderObject3D);
    }

    // TODO: Add shader sorting
    private void arrange_object(RenderObject3D obj)
    {
        foreach (RenderQueue3D sub in queue.sub_queues)
        {
            if (sub.reference_resource.equals(obj.model))
            {
                arrange_object_texture(obj, sub);
                return;
            }
        }

        RenderQueue3D sub_queue = new RenderQueue3D();
        sub_queue.reference_resource = obj.model;
        queue.sub_queues.add(sub_queue);

        arrange_object_texture(obj, sub_queue);
    }

    private void arrange_object_texture(RenderObject3D obj, RenderQueue3D queue)
    {
        if (obj is RenderLabel3D)
        {
            queue.objects.add(obj);
            return;
        }

        RenderBody3D body = obj as RenderBody3D;

        foreach (RenderQueue3D sub in queue.sub_queues)
        {
            if (body.texture == null)
            {
                if (sub.reference_resource == null)
                {
                    sub.objects.add(body);
                    return;
                }
            }
            else if (body.texture.equals(sub.reference_resource))
            {
                sub.objects.add(body);
                return;
            }
        }

        RenderQueue3D sub_queue = new RenderQueue3D();
        sub_queue.reference_resource = body.texture;
        queue.sub_queues.add(sub_queue);

        sub_queue.objects.add(body);
    }

    public RenderQueue3D queue { get; private set; }
    public ArrayList<LightSource> lights { get; private set; }
    public Mat4 scene_matrix { get; private set; }
    public Mat4 view_matrix { get; private set; }
    public float view_angle { get; private set; }
    public Rectangle rect { get; private set; }
    public Size2i screen_size { get; private set; }
}

public class RenderQueue3D
{
    public RenderQueue3D()
    {
        sub_queues = new ArrayList<RenderQueue3D>();
        objects = new ArrayList<RenderObject3D>();
    }

    public IResource? reference_resource { get; set; }
    public ArrayList<RenderQueue3D>? sub_queues { get; private set; }
    public ArrayList<RenderObject3D>? objects { get; private set; }
}