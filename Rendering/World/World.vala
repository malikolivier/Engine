using Gee;

public class World
{
	private WorldTransform world_transform = new WorldTransform();

	public void process(DeltaArgs args)
	{
		world_transform.process(args);
	}

	public void add_to_scene(RenderScene3D scene)
	{
		world_transform.add_to_scene(scene);

		if (active_camera != null)
			scene.set_camera(active_camera.camera);
	}

	public void add_object(WorldObject object)
	{
		world_transform.add_object(object);
	}

	public WorldCamera? active_camera { get; set; }
}

public class WorldTransform : WorldObject
{
	private ArrayList<WorldObject> objects = new ArrayList<WorldObject>();

	protected override void do_process(DeltaArgs args)
	{
		foreach (WorldObject object in objects)
			object.process(args);
	}

	public override void add_to_scene(RenderScene3D scene)
	{
		foreach (WorldObject object in objects)
			object.add_to_scene(scene);
	}

	public void add_object(WorldObject object)
	{
		objects.add(object);
		object.transform.change_parent(transform);
	}

	public void remove_object(WorldObject object)
	{
		objects.remove(object);
		object.transform.change_parent(null);
	}

	public void convert_object(WorldObject object)
	{
		objects.add(object);
		object.transform.convert_to_parent(transform);
	}

	public void unconvert_object(WorldObject object)
	{
		objects.remove(object);
		object.transform.convert_to_parent(null);
	}
}