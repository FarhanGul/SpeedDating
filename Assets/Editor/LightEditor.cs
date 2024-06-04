using UnityEngine;
using UnityEditor;

public class LightEditor : EditorWindow
{
    private float factor = 2.2f; // Default gamma value

    [MenuItem("Tools/Light Power Adjuster")]
    public static void ShowWindow()
    {
        GetWindow<LightEditor>("Light Power Adjuster");
    }

    private void OnGUI()
    {
        GUILayout.Label("Adjust Light Intensity Power", EditorStyles.boldLabel);

        factor = EditorGUILayout.FloatField("Factor", factor);

        if (GUILayout.Button("Adjust Lights"))
        {
            AdjustLights();
        }
    }

    private void AdjustLights()
    {
        Light[] lights = FindObjectsOfType<Light>();

        foreach (Light light in lights)
        {
            light.intensity = Mathf.Pow(light.intensity, 1 / factor);
        }

        Debug.Log("All light intensities adjusted by factor: " + factor);
    }
}