using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Change_Sorting : MonoBehaviour
{
    private Canvas _canvas;
    public int currentIndex = 3;
    public int TargetIndex = 4;
    private void Awake()
    {
        _canvas = GetComponent<Canvas>();
    }
    public void IncreaseIndex()
    {
        _canvas.sortingOrder = TargetIndex;
    }
    public void ResetIndex()
    {
        _canvas.sortingOrder = currentIndex;
    }
}
