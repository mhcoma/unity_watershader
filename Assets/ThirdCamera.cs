using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ThirdCamera : MonoBehaviour
{
	public Transform camera_Transform;
	public RenderTexture render_texture;
	public Transform clipping_plane;

	public float height = 5.0f;
	public float mul = 1.0f;

	Camera cam;

	void Start() {
		cam = GetComponent<Camera>();
		float aspect = cam.aspect;
		cam.targetTexture = render_texture;
		cam.aspect = aspect;
	}

	void Update() {
		transform.position = new Vector3(
			camera_Transform.position.x,
			-camera_Transform.position.y + 10,
			camera_Transform.position.z
		);

		transform.eulerAngles = new Vector3(
			-camera_Transform.eulerAngles.x,
			camera_Transform.eulerAngles.y,
			camera_Transform.eulerAngles.z + 180
		);

		cam.ResetProjectionMatrix();
		Plane plane = new Plane(clipping_plane.up, clipping_plane.position);
		Vector4 camera_space_clip_plane = camera_space_plane(cam, clipping_plane.position, plane.normal);
		cam.projectionMatrix = cam.CalculateObliqueMatrix(camera_space_clip_plane);
	}

	Vector4 camera_space_plane(Camera cam, Vector3 pos, Vector3 normal) {
		Matrix4x4 mat = cam.worldToCameraMatrix;
		Vector3 c_pos = mat.MultiplyPoint(pos);
		Vector3 c_normal = mat.MultiplyVector(normal).normalized * -1;
		return new Vector4(
			c_normal.x,
			c_normal.y,
			c_normal.z,
			-Vector3.Dot(c_pos, c_normal)
		);
	}
}
