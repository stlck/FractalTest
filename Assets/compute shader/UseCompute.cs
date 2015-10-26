using UnityEngine;
using System.Collections;

public class UseCompute : MonoBehaviour {

    public int index;
    public ComputeShader cs;
    public RenderTexture tex;
    public Camera cam;
    public Material material;

    ComputeBuffer buffer;
    const int count = 1024;
    const float size = 1.0f;

    struct Vert
    {
        public Vector3 position;
        public Vector3 color;
    }

	// Use this for initialization
	void Start () {
        buffer = new ComputeBuffer(count, sizeof(float) * 6, ComputeBufferType.Default);

        Vert[] points = new Vert[count];

        Random.seed = 0;
        for (int i = 0; i < count; i++)
        {
            points[i] = new Vert();

            points[i].position = new Vector3();
            points[i].position.x = Random.Range(-size, size);
            points[i].position.y = Random.Range(-size, size);
            points[i].position.z = 0;

            points[i].color = new Vector3();
            points[i].color.x = Random.value > 0.5f ? 0.0f : 1.0f;
            points[i].color.y = Random.value > 0.5f ? 0.0f : 1.0f;
            points[i].color.z = Random.value > 0.5f ? 0.0f : 1.0f;
        }

        buffer.SetData(points);

        index = cs.FindKernel("CSMain");

       /* tex = new RenderTexture(64, 64, 24);
        tex.enableRandomWrite = true;
        tex.Create();*/

        cs.SetBuffer(index, "data", buffer);
        cs.SetInt("count", count);
     //   cs.SetTexture(index, "Result", tex);
        cs.Dispatch(index, 1, 1,1);

       /* if (cam != null)
            cam.targetTexture = tex;*/
	}

    void OnPostRender()
    {
        material.SetPass(0);
        material.SetBuffer("buffer", buffer);
        Graphics.DrawProcedural(MeshTopology.Points, count, 1);
    }

    void OnDestroy()
    {
        if (buffer != null)
        buffer.Release();
        //tex.Release();
    }
}
