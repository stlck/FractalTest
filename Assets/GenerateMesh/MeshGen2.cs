using UnityEngine;
using System.Linq;
using System.Collections;
using System.Collections.Generic;
using System;

public class MeshGen2 : MonoBehaviour {


    Mesh mesh;
    float timer;
    bool direction = false;
    public int resolution = 20;
    public int size = 200;

    // Use this for initialization
    void Start()
    {
        mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;

        Create();
    }

    public void Create()
    {
        var newgrid = new List<Vector3>();
        var newtriangles = new List<int>();
        var index = 0;
        float h = resolution / 2;
        var newcolors = new List<Vector2>();

        for (int i = 0; i < size; i += resolution)
        {
            for (int j = 0; j < size; j += resolution)
            {

                newgrid.Add(new Vector3(i, (int)HeightMap.Instance.getHeightWithCliffs(i, j, transform.position), j));
                newgrid.Add(new Vector3(i, (int)HeightMap.Instance.getHeightWithCliffs(i, j + resolution, transform.position), j + resolution));
                newgrid.Add(new Vector3(i + h, (int)HeightMap.Instance.getHeightWithCliffs(i + h, j + h, transform.position), j + h));

                newgrid.Add(new Vector3(i, (int)HeightMap.Instance.getHeightWithCliffs(i, j, transform.position), j));
                newgrid.Add(new Vector3(i + h, (int)HeightMap.Instance.getHeightWithCliffs(i + h, j + h, transform.position), j + h));
                newgrid.Add(new Vector3(i + resolution, (int)HeightMap.Instance.getHeightWithCliffs(i + resolution, j, transform.position), j));

                newgrid.Add(new Vector3(i, (int)HeightMap.Instance.getHeightWithCliffs(i, j + resolution, transform.position), j + resolution));
                newgrid.Add(new Vector3(i + resolution, (int)HeightMap.Instance.getHeightWithCliffs(i + resolution, j + resolution, transform.position), j + resolution));
                newgrid.Add(new Vector3(i + h, (int)HeightMap.Instance.getHeightWithCliffs(i + h, j + h, transform.position), j + h));

                newgrid.Add(new Vector3(i + resolution, (int)HeightMap.Instance.getHeightWithCliffs(i + resolution, j, transform.position), j));
                newgrid.Add(new Vector3(i + h, (int)HeightMap.Instance.getHeightWithCliffs(i + h, j + h, transform.position), j + h));
                newgrid.Add(new Vector3(i + resolution, (int)HeightMap.Instance.getHeightWithCliffs(i + resolution, j + resolution, transform.position), j + resolution));

                //create all 4

                //0 1
                // 2
                //
                //3
                // 4
                //5

                //  6
                // 8
                //  7

                //
                // 10
                //9 11

                //if(i < count - 1 && j < count - 1 )
                {
                    //0 1
                    // 4
                    //2 3
                    newtriangles.Add(index++);
                    newtriangles.Add(index++);
                    newtriangles.Add(index++);

                    newtriangles.Add(index++);
                    newtriangles.Add(index++);
                    newtriangles.Add(index++);

                    newtriangles.Add(index++);
                    newtriangles.Add(index++);
                    newtriangles.Add(index++);

                    newtriangles.Add(index++);
                    newtriangles.Add(index++);
                    newtriangles.Add(index++);
                }
                //for(int x = 0; x < 12; x++)
                //	newcolors.Add (Vector2.one);
                //index += 12;
            }
        }
        mesh.vertices = newgrid.ToArray();
        mesh.SetTriangles(newtriangles.ToArray(), 0);

        foreach (var v in mesh.vertices)
            newcolors.Add(Vector2.up * HeightMap.Instance.getTexturePos(v.x, v.z, transform.position) + Vector2.right * (v.y + 25) / 50);

        mesh.uv = newcolors.ToArray();
        //mesh.colors32 = newcolors.ToArray();
        mesh.RecalculateBounds();

        //transform.position = Vector3.zero;
        mesh.RecalculateNormals();
        GetComponent<MeshCollider>().sharedMesh = mesh;
    }

    public void Flatten(Vector3 point)
    {
        timer += Time.deltaTime / 2;
        Vector3[] vertices = mesh.vertices;
        int i = 0;
        while (i < vertices.Length)
        {
            if (direction)
                vertices[i].y = Mathf.SmoothStep(0, 1, Mathf.Abs(timer - (vertices[i].x % 2)));
            else
                vertices[i].y = Mathf.SmoothStep(1, 0, Mathf.Abs(timer - (vertices[i].x % 2)));
            i++;
        }
        if (timer >= 1)
        {
            timer = 0;
            direction = !direction;
        }
        mesh.vertices = vertices;
        mesh.RecalculateBounds();
    }
}
