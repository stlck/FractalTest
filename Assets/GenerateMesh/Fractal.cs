using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

public class Fractal : MonoBehaviour {

    public Mesh TargetMesh;
    private float s = -1;
    private float r = .5f;
    private float f = 1;
    public float c = -.864f;
    public int loopCount = 2;

    public Transform cube;
    public List<Vector3> points = new List<Vector3>();
    List<Transform> cubes = new List<Transform>();
    Mesh mesh;
	// Use this for initialization
	void Start () {
	    
	}
	
	// Update is called once per frame
	void Update () {
    	 
	}

    void OnGUI()
    {
        GUILayout.Label("Loop " + loopCount);
        loopCount = (int) GUILayout.HorizontalSlider((float)loopCount, 0, 100);
        if (GUILayout.Button("MandelBrot"))
            MandelBrot();
        if (GUILayout.Button("MandelBox"))
            FractalMesh();
        if (GUILayout.Button("SpawnCubes"))
            SpawnCubes();
    }

    Vector3[] getVertices()
    {
        if (TargetMesh == null)
            TargetMesh = GetComponent<MeshFilter>().mesh;

       return TargetMesh.vertices;
    }

    void setVertices(Vector3[] vertices)
    {
        TargetMesh.SetVertices(vertices.ToList());
    }

    public void MandelBrot()
    {
        var vertices = getVertices();

        for (int j = 0; j < vertices.Length; j++)
        {
            vertices[j].x = vertices[j].x + c;
            vertices[j].y = vertices[j].y + c;
            vertices[j].z = vertices[j].z + c;
        }

        for (int i = 0; i < loopCount; i++)
        {
            for (int j = 0; j < vertices.Length; j++)
            {
                vertices[j].x = vertices[j].x * vertices[j].x + c;
                vertices[j].y = vertices[j].y * vertices[j].x + c;
                vertices[j].z = vertices[j].z * vertices[j].x + c;
            }
        }

        setVertices(vertices);
    }

    public void SpawnCubes()
    {
        var dim = 20;

        if (points.Count == 0)
        {
            points = new List<Vector3>();

            for (int x = 0; x < dim; x++)
                //for (int y = -dim; y < dim; y++)
                    for (int z = 0; z < dim; z++)
                    {
                        points.Add(new Vector3(x, Mathf.PerlinNoise(x /c, z/c), z));
                    }
            mesh = new Mesh();
            GetComponent<MeshFilter>().mesh = mesh;
            mesh.SetVertices(points);
            
            var triangles = new List<int>();
            // triangles
            for(int i = 0; i < points.Count - dim; i++)
            {
                if( i % 2 == 0)
                {
                    triangles.Add(i);
                    triangles.Add(i + 1);
                    triangles.Add(i + dim); 
                }
                else
                {
                    triangles.Add(i);
                    triangles.Add(i + dim);
                    triangles.Add(i + dim - 1);
                }
            }
            mesh.SetTriangles(triangles.ToArray(), 0);
            /*foreach (var p in points)
            {
                var c = Instantiate(cube, p, cube.rotation) as Transform;
                cubes.Add(c);
            }*/

            var parr = points.ToArray();
            for (int j = 0; j < points.Count; j++)
            {
                parr[j].x = parr[j].x + c;
                parr[j].y = parr[j].y + c;
                parr[j].z = parr[j].z + c;
            }
            points = parr.ToList();
        }

        for(int i = 0; i < loopCount; i++)
        {
            for (int j = 0; j < points.Count; j++)
                points[j] = mandelBox(points[j]);
        }

        mesh.SetVertices(points);
        mesh.RecalculateBounds();
        mesh.RecalculateNormals();
        GetComponent<MeshFilter>().sharedMesh = mesh;
        //for (int i = 0; i < points.Count; i++)
        //{
           // cubes[i].position = points[i];
           // cubes[i].localScale = Vector3.one* Mathf.PerlinNoise(points[i].x, points[i].z);
        //}
    }


    public void FractalMesh()
    {
        var vertices = getVertices();

        for (int j = 0; j < vertices.Length; j++)
        {
            vertices[j].x = vertices[j].x + c;
            vertices[j].y = vertices[j].y + c;
            vertices[j].z = vertices[j].z + c;
        }

        //foreach (var v in vertices)
        for (int x = 0; x < loopCount; x++)
        {
            for (int i = 0; i < vertices.Length; i++)
                vertices[i] = mandelBox(vertices[i]);
        }

        setVertices(vertices);
    }

    Vector3 mandelBox(Vector3 v)
    {
        v = s * ballFold(f * boxFold(v)) + c * Vector3.one;
        return v;
    }

    Vector3 boxFold(Vector3 v)
    {
        if (v.x > 1)
            v.x = 2 - v.x;
        else if (v.x < -1)
            v.x = -2 - v.x;

        if (v.y > 1)
            v.y = 2 - v.y;
        else if (v.y < -1)
            v.y = -2 - v.y;

        if (v.z > 1)
            v.z = 2 - v.z;
        else if (v.z < -1)
            v.z = -2 - v.z;

        return v;
    }

    Vector3 ballFold( Vector3 v)
    {
        var m = v.magnitude;
        if (m < r)
            m = m / Mathf.Pow(r,2);
        else if (m < 1)
            m = 1 / m;

        v = Vector3.ClampMagnitude(v, m);
        //v.Scale( m);
        return v;
    }
}
