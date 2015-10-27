using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class SpawnTerrain : MonoBehaviour {

	public MeshGen2 TerrainPiece;
	public List<Vector3> Positions = new List<Vector3>();

	void Awake()
	{
		StartCoroutine(spawn ());
	}

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	IEnumerator spawn () {
	
		while (true) {
			SpawnAroundTransform();
			yield return new WaitForSeconds(10f);
		}
	}

	void SpawnAroundTransform()
	{
		var p = transform.position;

		p.y = 0;
		//p.x = p.x - p.x % 100;
		//p.z = p.z - p.z % 100;
		
		for (int i  = -2; i <= 1; i++)
			for (int j = -2; j <= 1; j++) {
                SpawnAtPosition(p + Vector3.right * i * TerrainPiece.size + Vector3.forward * j * TerrainPiece.size);
			}

	}

	void SpawnAtPosition(Vector3 v)
	{
		var pos = Vector3.zero;
        pos.x = v.x - v.x % TerrainPiece.size;
        pos.z = v.z - v.z % TerrainPiece.size;

		if (!Positions.Contains (pos)) {
			Instantiate(TerrainPiece, pos, Quaternion.identity);
			Positions.Add(pos);
		}
	}
}
