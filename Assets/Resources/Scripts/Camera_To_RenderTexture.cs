using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class Camera_To_RenderTexture : MonoBehaviour
{
    private RenderTexture RT;
    public Material _material;
    public float m_blurAmount = 0.005f;
    private void CheckResources()
    {
        if (_material == null) return;
    }
    public void ChangeBlurValues()
    {
        _material.SetFloat("_BlurAmount", m_blurAmount);
    }
    public void ResetBlurValues()
    {
        _material.SetFloat("_BlurAmount",0.0f);
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        CheckResources();

        RT = RenderTexture.GetTemporary(source.width, source.height, 0, source.format, RenderTextureReadWrite.Linear);
        RT.wrapMode = TextureWrapMode.Clamp;
        RT.filterMode = FilterMode.Bilinear;
        RT.name = "CameraUI";
        RT.Create();

        Graphics.Blit(source, RT);
        _material.SetTexture("_MainTex", RT);
        Graphics.Blit(null, destination,_material);    

        RenderTexture.ReleaseTemporary(RT);
    }

    void OnDisable()
    {
        if (RT != null)
        {
            RenderTexture.ReleaseTemporary(RT);
        }
        ResetBlurValues();
    }
}
