namespace Engine
{
	public class WorldObjectTransformable : WorldObject
	{
		private Transformable3D object;

		public WorldObjectTransformable(Transformable3D object)
		{
			this.object = object;
			object.transform = transform;
		}

		protected override void add_to_scene(RenderScene3D scene)
		{
			scene.add_object(object);
		}
	}
}