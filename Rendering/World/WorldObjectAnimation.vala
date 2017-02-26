public class WorldObjectAnimation
{
	public signal void start(WorldObjectAnimation animation);
	public signal void animate(WorldObjectAnimation animation, float time);
	public signal void finish(WorldObjectAnimation animation);
	
	private Animation animation;

	public WorldObjectAnimation(AnimationTime time)
	{
		animation = new Animation(time);
		animation.animate_start.connect(animation_start);
		animation.animate.connect(animation_start);
		animation.post_finished.connect(animation_finished);
	}

	public void process(DeltaArgs args)
	{
		animation.process(args);
	}

	public void relative_position(Path3D path)
	{
		position_path = path;
		use_position = true;
		relative_position = true;
	}

	public void absolute_position(Path3D path, Vec3 start_position)
	{
		position_path = path;
		use_position = true;
		relative_position = false;
		this.start_position = start_position;
	}

	public void relative_scale(Path3D path)
	{
		scale_path = path;
		use_scale = true;
		relative_scale = true;
	}

	public void absolute_scale(PathQuat path, Quat start_rotation)
	{
		rotation_path = path;
		use_rotation = true;
		relative_rotation = false;
		this.start_rotation = start_rotation;
	}

	private void animation_start()
	{
		start(this);
	}

	private void animation_animate(float time)
	{
		animate(this, time);
	}

	private void animation_finished()
	{
		finished(this);
	}

	public bool use_position { get; private set; }
	public bool use_scale { get; private set; }
	public bool use_rotation { get; private set; }

	public bool relative_position { get; private set; }
	public bool relative_scale { get; private set; }
	public bool relative_rotation { get; private set; }
	
	public Vec3 start_position { get; set; }
	public Vec3 start_scale { get; set; }
	public Quat start_rotation { get; set; }

	public Path3D position_path { get; private set; }
	public Path3D position_path { get; private set; }
	public PathQuat position_path { get; private set; }
	
	public Curve curve { get { return animation.curve; } set { animation.curve = value; } }
}