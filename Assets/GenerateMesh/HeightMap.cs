using UnityEngine;
using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Networking;
using UnityEngine.Events;

public class HeightMap : MonoBehaviour {

	private static HeightMap _instance;
	public static HeightMap Instance
	{
		get{
			return _instance;
		}
	}

	public int StandardHeight = 10;
    public float MountainModifier;
	public int MaxHeight = 20;
    public float seed;
    public float texseed;

	public Dictionary<Vector2, float> heights = new Dictionary<Vector2, float>();

	void Awake()
	{
		_instance = this;
        seed = Random.Range(0.020f, .032f);
        texseed = Random.Range(0.001f, .008f);
        MountainModifier = Random.Range(1.86f, 3.5f);
        //DontDestroyOnLoad(gameObject);
	}

    void OnEnable()
    {
        //if ((isServer || !NetworkClient.active) && seed == 0)
        //{
        //    seed = Random.Range(0.020f, .032f);
        //    texseed = Random.Range(0.001f, .008f);
        //    MountainModifier = Random.Range(1.86f, 3.5f);
        //}
    }

    void Start()
    {
        
    }

    public float SampleHeight(float x, float y) {  
		var ret = Mathf.PerlinNoise(x, y);
		return ret;
	}

	public float getHeight(float x, float y, Vector3 offset)
	{
		//offset /= 10;
		var ret = SampleHeight(seed * (x + offset.x), seed * (y + offset.z)) * StandardHeight - StandardHeight/2 ;
		ret += SampleHeight ((seed / MountainModifier) * (x + offset.x), (seed / MountainModifier) * (y + offset.z)) * MaxHeight - MaxHeight / 2;
		return (int)ret;
	}

    public float getHeightWithCliffs(float x, float y, Vector3 offset)
    {
        return 1;
        var ret = SampleHeight(seed * (x + offset.x), seed * (y + offset.z));
        ret *= StandardHeight - StandardHeight / 2;
        var mountain = SampleHeight((seed / MountainModifier) * (x + offset.x), (seed / MountainModifier) * (y + offset.z));
        if (mountain >= .7f )
            ret += (mountain -.7f) * MaxHeight ;
        else if (mountain <= .3f)
            ret -= (.3f - mountain ) * MaxHeight ;

        return (int)ret;
    }

	public float getTexturePos(float x, float y, Vector3 offset)
	{
		var ret = SampleHeight(texseed  * (x + offset.x), texseed  * (y + offset.z)) ;

		return ret;
	}
}