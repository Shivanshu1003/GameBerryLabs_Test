using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Camera_Update_Cull : MonoBehaviour
{
    private Camera _camera;
    
    public void LeftCardOn()
    {
        _camera = GetComponent<Camera>();
        _camera.cullingMask = 1 << 6;
    }
    public void MiddleCardOn()
    {
        _camera = GetComponent<Camera>();
        _camera.cullingMask = 1 << 7;
    }
    public void RightCardOn()
    {
        _camera = GetComponent<Camera>();
        _camera.cullingMask = 1 << 8;
    }
}
