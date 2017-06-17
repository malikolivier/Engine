public class RenderModel : IResource
{
    public RenderModel(IModelResourceHandle handle, string name, Vec3 size)
    {
        this.handle = handle;
        this.name = name;
        this.size = size;
    }

    public override bool equals(IResource? other)
    {
        return other != null && handle == (other as RenderModel).handle;
    }

    public IModelResourceHandle handle { get; private set; }
    public string name { get; private set; }
    public Vec3 size { get; private set; }
}