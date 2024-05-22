using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Change_Sorting : MonoBehaviour
{
    private Canvas _canvas;

    private void Awake()
    {
        _canvas = GetComponent<Canvas>();
    }
    public void IncreaseIndex()
    {
        _canvas.sortingOrder = 3;
    }
    public void ResetIndex()
    {
        _canvas.sortingOrder = 2;
    }
}
