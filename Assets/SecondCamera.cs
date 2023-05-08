using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SecondCamera : MonoBehaviour
{
	public RenderTexture render_texture;

	void Start() {
		float aspect = GetComponent<Camera>().aspect;
		GetComponent<Camera>().targetTexture = render_texture;
		GetComponent<Camera>().aspect = aspect;
	}

	void Update() {

	}
}
