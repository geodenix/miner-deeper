using UnityEngine;

namespace MinerDeeper
{
    public sealed class PrototypeBootstrap : MonoBehaviour
    {
        private Transform miner;
        private Camera cam;
        private Light headLamp;

        private void Start()
        {
            Application.targetFrameRate = 60;
            Screen.orientation = ScreenOrientation.LandscapeLeft;

            CreateEnvironment();
            CreateMiner();
            CreateMine();
        }

        private void CreateEnvironment()
        {
            RenderSettings.ambientLight = new Color(0.09f, 0.11f, 0.13f);

            var sunGo = new GameObject("Directional Light");
            var sun = sunGo.AddComponent<Light>();
            sun.type = LightType.Directional;
            sun.intensity = 0.65f;
            sun.color = new Color(1.0f, 0.92f, 0.78f);
            sunGo.transform.rotation = Quaternion.Euler(48f, -32f, 0f);

            var floor = GameObject.CreatePrimitive(PrimitiveType.Cube);
            floor.name = "Mine Floor";
            floor.transform.position = new Vector3(0f, -0.3f, -8f);
            floor.transform.localScale = new Vector3(18f, 0.5f, 30f);
            floor.GetComponent<Renderer>().material.color = new Color(0.15f, 0.14f, 0.13f);
        }

        private void CreateMiner()
        {
            var minerGo = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            minerGo.name = "Miner";
            minerGo.transform.position = new Vector3(0f, 1f, 1.5f);
            minerGo.transform.localScale = new Vector3(0.72f, 0.82f, 0.72f);
            minerGo.GetComponent<Renderer>().material.color = new Color(0.16f, 0.36f, 0.48f);
            miner = minerGo.transform;

            var helmet = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            helmet.name = "Helmet";
            helmet.transform.SetParent(miner);
            helmet.transform.localPosition = new Vector3(0f, 0.72f, 0f);
            helmet.transform.localScale = new Vector3(0.65f, 0.10f, 0.65f);
            helmet.GetComponent<Renderer>().material.color = new Color(0.92f, 0.66f, 0.18f);
            Destroy(helmet.GetComponent<Collider>());

            var camGo = new GameObject("Third Person Camera");
            cam = camGo.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.025f, 0.03f, 0.04f);
            cam.fieldOfView = 62f;

            var lampGo = new GameObject("Head Lamp");
            lampGo.transform.SetParent(camGo.transform);
            lampGo.transform.localPosition = Vector3.zero;
            headLamp = lampGo.AddComponent<Light>();
            headLamp.type = LightType.Spot;
            headLamp.range = 16f;
            headLamp.spotAngle = 48f;
            headLamp.intensity = 7f;
            headLamp.color = new Color(1f, 0.91f, 0.72f);

            UpdateCamera(true);
        }

        private void CreateMine()
        {
            var random = new System.Random(42);
            for (var z = -2; z >= -18; z--)
            {
                for (var x = -5; x <= 5; x++)
                {
                    if (z > -6 && Mathf.Abs(x) <= 1)
                        continue;

                    var cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
                    cube.name = "MineBlock";
                    cube.transform.position = new Vector3(x * 1.25f, 0.65f, z * 1.25f);
                    cube.transform.localScale = Vector3.one * 1.2f;

                    var oreRoll = random.NextDouble();
                    var color = new Color(0.31f, 0.29f, 0.27f);
                    if (oreRoll < 0.09) color = new Color(0.12f, 0.13f, 0.14f);       // coal
                    else if (oreRoll < 0.15) color = new Color(0.46f, 0.31f, 0.22f);  // iron
                    else if (oreRoll < 0.18) color = new Color(0.72f, 0.52f, 0.12f);  // gold
                    cube.GetComponent<Renderer>().material.color = color;
                }
            }
        }

        private void Update()
        {
            if (miner == null) return;

            var x = Input.GetAxisRaw("Horizontal");
            var z = Input.GetAxisRaw("Vertical");
            var input = new Vector3(x, 0f, z);
            if (input.sqrMagnitude > 1f) input.Normalize();

            if (input.sqrMagnitude > 0.01f)
            {
                miner.position += input * (3.6f * Time.deltaTime);
                miner.rotation = Quaternion.Slerp(
                    miner.rotation,
                    Quaternion.LookRotation(input, Vector3.up),
                    Mathf.Clamp01(Time.deltaTime * 12f)
                );
            }

            UpdateCamera(false);
        }

        private void UpdateCamera(bool snap)
        {
            if (cam == null || miner == null) return;
            var target = miner.position + new Vector3(0f, 3.0f, 5.4f);
            cam.transform.position = snap
                ? target
                : Vector3.Lerp(cam.transform.position, target, Mathf.Clamp01(Time.deltaTime * 7f));
            cam.transform.LookAt(miner.position + Vector3.up * 0.75f);
        }

        private void OnGUI()
        {
            var title = new GUIStyle(GUI.skin.label)
            {
                fontSize = Mathf.RoundToInt(Screen.height * 0.035f),
                normal = { textColor = new Color(0.95f, 0.81f, 0.38f) }
            };
            GUI.Label(new Rect(18, 12, Screen.width * 0.8f, 60), "ШАХТЁР: ГЛУБЖЕ! • UNITY ПРОТОТИП", title);

            var info = new GUIStyle(GUI.skin.label)
            {
                fontSize = Mathf.RoundToInt(Screen.height * 0.024f),
                normal = { textColor = Color.white }
            };
            GUI.Label(new Rect(20, 62, Screen.width * 0.9f, 60), "Unity 6.3 LTS • URP • Android CI готов", info);
        }
    }
}
