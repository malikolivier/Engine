public class World
{
	public void add_scene(RenderScene3D scene)
	{
		
	}
}

public class WorldTransform
{
	private ArrayList<WorldTransform> transforms = new ArrayList<WorldTransform>();
	private ArrayList<WorldObject> objects = new ArrayList<WorldObject>();

	public WorldTransform()
	{
		transform = new Transform();
	}

	public void add_scene(RenderScene3D scene)
	{
		foreach (WorldObject object in objects)
			object.add_object(scene);

		foreach (WorldTransform transform in transforms)
			transform.add_scene(scene);
	}

	public void add_transform(WorldTransform transform)
	{
		transforms.add(transform);
	}

	public void remove_transform(WorldTransform transform)
	{
		transforms.remove(transform);
	}

	public void add_object(WorldObject object)
	{
		objects.add(object);
	}

	public void remove_object(WorldObject object)
	{
		objects.remove(object);
	}

	public Transform transform { get; private set; }
}