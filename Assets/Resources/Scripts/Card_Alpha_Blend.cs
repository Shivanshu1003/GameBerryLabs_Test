using System.Collections;
using System.Collections.Generic;
using System.Runtime.ConstrainedExecution;
using UnityEngine;

public class Card_Alpha_Blend : MonoBehaviour
{
    public Material m_material;
    public float m_speed = 0.1f;
    public float m_blurAmount = 0.005f;
    private float value;

    private Coroutine currentCoroutine;
    public void SetBlur()
    {
        m_material.SetFloat("_Blend", m_blurAmount);
    }
    public void ResetBlur()
    {
        m_material.SetFloat("_Blend",0.0f);
    }
    public void IncreaseValue()
    {
        if (currentCoroutine != null)
        {
            StopCoroutine(currentCoroutine);
        }
        currentCoroutine = StartCoroutine(IncreaseBlend());
    }

    public void DecreaseValue()
    {
        if (currentCoroutine != null)
        {
            StopCoroutine(currentCoroutine);
        }
        currentCoroutine = StartCoroutine(DecreaseBlend());
    }

    private IEnumerator IncreaseBlend()
    {
        value = 0.0f;
        while (value < 1.0f)
        {
            m_material.SetFloat("_Blend", value);
            value += m_speed * Time.deltaTime;
            yield return null; // Wait for the next frame
        }
        m_material.SetFloat("_Blend", 1.0f); // Ensure it ends exactly at 1.0f
    }

    private IEnumerator DecreaseBlend()
    {
        value = 1.0f;
        while (value > 0.0f)
        {
            m_material.SetFloat("_Blend", value);
            value -= m_speed * Time.deltaTime;
            yield return null; // Wait for the next frame
        }
        m_material.SetFloat("_Blend", 0.0f); // Ensure it ends exactly at 0.0f
    }

    private void OnDisable()
    {
        m_material.SetFloat("_Blend", 1.0f);
    }
}
