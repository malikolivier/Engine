public abstract class Path3D
{
	public abstract Vec3 map(float time);

	public Vec3 start { get; set; }
}

public class LinearPath3D : Path3D
{
	public LinearPath3D(Vec3 end)
	{
		this.end = end;
	}

	public override Vec3 map(float time)
	{
		return Vec3.lerp(start, end, time);
	}

	public Vec3 end { get; private set; }
}

public abstract class PathQuat
{
	public abstract Quat map(float time);

	public Quat start { get; set; }
}

public class LinearPathQuat : PathQuat
{
	public LinearPathQuat(Quat end)
	{
		this.end = end;
	}

	public override Quat map(float time)
	{
		return Quat.slerp(start, end, time);
	}

	public Quat end { get; private set; }
}