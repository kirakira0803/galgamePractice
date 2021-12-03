using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Naninovel;

public class startGal : MonoBehaviour
{
    public Canvas canvas;
    // Start is called before the first frame update
    void Start()
    {
        AsyncStart();
    }
    public void Click()
    {
        AsyncClick();
    }
    async void AsyncStart()
    {
        await RuntimeInitializer.InitializeAsync(null,null,canvas);
    }
    async void AsyncClick()
    {
        var player = Engine.GetService<IScriptPlayer>();

        await player.PreloadAndPlayAsync("script");
        canvas.gameObject.SetActive(false);
    }
}
