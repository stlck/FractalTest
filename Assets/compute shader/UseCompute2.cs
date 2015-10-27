using UnityEngine;
using System.Collections;

public class UseCompute2 : MonoBehaviour {

    public RenderTexture tex;
    public ComputeShader cs;
    public Material target;
    int index;
    int mod = 4;
	// Use this for initialization
	void Start () {
        
        tex = new RenderTexture(1024, 1024, 1);
        tex.enableRandomWrite = true;
        tex.Create();

        index = cs.FindKernel("CSMain2");
        //cs.SetInt("modOff", (int)mod);
        cs.SetTexture(index, "tex", tex);
        cs.Dispatch(index, 1024 / 8, 1024 / 8, 1);

        target.SetTexture(0, tex);
    }
	
	// Update is called once per frame
	void Update () {
      /*  mod ++;

        cs.SetInt("modOff", (int)mod);
        cs.Dispatch(index, 128 / 8, 128 / 8, 1);

        if (mod >= 10)
            mod = 0;*/
	}

    void OnDestroy()
    {
        tex.Release();
    }
}
