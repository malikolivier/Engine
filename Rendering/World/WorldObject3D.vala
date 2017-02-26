public class WorldObject3D : WorldObject3D
{
	private Transformable3D object;

	public WorldObject3D(Transformable3D object)
	{
		this.object = object;
	}

	protected override void apply_transform(Transform transform)
	{
		object.transform = transform;
	}

	protected override void add_object(RenderScene3D scene)
	{
		scene.add_object(object);
	}
}