using Gee;

public abstract class Transformable3D : Object
{
    protected Transformable3D()
    {
        transform = new Transform();
    }

    public Transformable3D copy()
    {
        Transformable3D t = copy_transformable();
        t.transform = transform.copy();

        return t;
    }

    protected abstract Transformable3D copy_transformable();
    public virtual Transform get_final_transform() { return transform; }
    
    public Transform transform { get; private set; }
}

public class RenderGeometry3D : Transformable3D
{
    public RenderGeometry3D()
    {
        geometry = new ArrayList<Transformable3D>();
    }

    public RenderGeometry3D.with_objects(ArrayList<RenderObject3D> objects)
    {
        geometry = new ArrayList<Transformable3D>();
        geometry.add_all(objects);
    }

    public RenderGeometry3D.with_transformables(ArrayList<Transformable3D> geometry)
    {
        this.geometry = geometry;
    }

    public override Transformable3D copy_transformable()
    {
        RenderGeometry3D geo = new RenderGeometry3D();

        foreach (Transformable3D transformable in geometry)
            geo.geometry.add(transformable.copy());

        return geo;
    }

    public ArrayList<Transformable3D> geometry { get; private set; }
}
