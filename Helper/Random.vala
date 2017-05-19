public class Random
{
    private Rand rnd;

    public Random()
    {
        rnd = new Rand();
    }

    public Random.seed(int seed)
    {
        rnd = new Rand.with_seed(seed);
    }

    public int int_range(int min, int max)
    {
        return rnd.int_range(min, max);
    }

    public float next_float()
    {
        return (float)rnd.next_double();
    }

    public float float_range(float min, float max)
    {
        return min + next_float() * (max - min);
    }

    public bool next_bool()
    {
        return next_float() > 0.5f;
    }
}
