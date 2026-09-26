using System;
using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace MinerDeeper.Editor
{
    public static class UnityBuild
    {
        private const string ScenePath = "Assets/Scenes/Main.unity";
        private const string PipelinePath = "Assets/Settings/MinerDeeperURP.asset";
        private const string RendererPath = "Assets/Settings/MinerDeeperRenderer.asset";

        public static void BuildAndroid()
        {
            EnsureFolders();
            ConfigureUrp();
            CreateScene();
            ConfigurePlayer();

            var output = Path.GetFullPath(Path.Combine(Application.dataPath, "../Builds/Android/MinerDeeperUnity.apk"));
            Directory.CreateDirectory(Path.GetDirectoryName(output)!);

            var options = new BuildPlayerOptions
            {
                scenes = new[] { ScenePath },
                locationPathName = output,
                target = BuildTarget.Android,
                options = BuildOptions.Development
            };

            var report = BuildPipeline.BuildPlayer(options);
            if (report.summary.result != BuildResult.Succeeded)
                throw new Exception($"Unity Android build failed: {report.summary.result}");

            Debug.Log($"UNITY_ANDROID_APK={output}");
        }

        private static void EnsureFolders()
        {
            if (!AssetDatabase.IsValidFolder("Assets/Scenes"))
                AssetDatabase.CreateFolder("Assets", "Scenes");
            if (!AssetDatabase.IsValidFolder("Assets/Settings"))
                AssetDatabase.CreateFolder("Assets", "Settings");
        }

        private static void ConfigureUrp()
        {
            var pipeline = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(PipelinePath);
            if (pipeline == null)
            {
                var renderer = ScriptableObject.CreateInstance<UniversalRendererData>();
                AssetDatabase.CreateAsset(renderer, RendererPath);

                pipeline = UniversalRenderPipelineAsset.Create(renderer);
                pipeline.renderScale = 0.90f;
                pipeline.shadowDistance = 30f;
                pipeline.shadowCascadeCount = 1;
                AssetDatabase.CreateAsset(pipeline, PipelinePath);
            }

            GraphicsSettings.defaultRenderPipeline = pipeline;
            QualitySettings.renderPipeline = pipeline;
            AssetDatabase.SaveAssets();
        }

        private static void CreateScene()
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var root = new GameObject("MinerDeeperUnity");
            root.AddComponent<MinerDeeper.PrototypeBootstrap>();
            EditorSceneManager.SaveScene(scene, ScenePath);
            AssetDatabase.SaveAssets();
        }

        private static void ConfigurePlayer()
        {
            PlayerSettings.productName = "Шахтёр: Глубже! Unity";
            PlayerSettings.companyName = "Geodenix";
            PlayerSettings.bundleVersion = "0.1.0";
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android, "com.geodenix.minerdeeper.unity");
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel26;
            PlayerSettings.Android.targetSdkVersion = AndroidSdkVersions.AndroidApiLevelAuto;
            EditorUserBuildSettings.buildAppBundle = false;
        }
    }
}
