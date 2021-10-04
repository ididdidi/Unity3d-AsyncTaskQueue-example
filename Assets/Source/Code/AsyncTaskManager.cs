using System.Threading;
using System.Threading.Tasks;
using UnityEngine;
using ru.mofrison.AsyncTasks;

namespace ru.mofrison.Unity3d
{
    public class AsyncTaskManager : MonoBehaviour
    {
        private readonly AsyncTaskQueue taskQueue = new AsyncTaskQueue();
        private int N = 0;

        // Start is called before the first frame update
        void Start()
        {
            // Add tasks to the queue 
            for (int i=0; i< 10; i++)
            {
                var index = i;
                var priority = i % 4 != 0 ? AsyncTask.Priority.Default : AsyncTask.Priority.High;
                taskQueue.Add((cancellationToken) => TestTask(cancellationToken, index), priority);
            }
            taskQueue.Add((cancellationToken) => TestTask(cancellationToken, 10), AsyncTask.Priority.Interrupt);
        }

        // Update is called once per frame
        async void Update()
        {
            if (taskQueue.NextIsRedy)
            {
                var task = taskQueue.GetNext();
                try
                {
                    await task.Run();
                }
                catch (AsyncTaskQueue.Exception e)
                {
                    Debug.LogError(e.Message);
                    taskQueue.Add(task);
                }
            }
        }

        async Task TestTask(CancellationTokenSource cancellationToken, int n)
        {
            Debug.Log(string.Format("Start task nuber: {0}, TaskQueue.Count: {1}", n, taskQueue.Count));
            if (n != N)
            {
                N = n;
                // Add a task already at runtime
                taskQueue.Add((ct) => TestTask(ct, n), AsyncTask.Priority.Interrupt);
            }

            await Task.Run(() => {
                int i = 10;
                while (i-- > 0)
                {
                    // If there is a signal to terminate, exit the task. 
                    if (cancellationToken.IsCancellationRequested)
                    {
                        Debug.LogWarning(string.Format("Canceled task nuber: {0}, TaskQueue.Count: {1}", n, taskQueue.Count));
                        return;
                    }
                    Thread.Sleep(200);
                }
                Debug.Log(string.Format("Finished task nuber: {0}, TaskQueue.Count: {1}", n, taskQueue.Count));
            });
        }

        private void OnDestroy()
        {
            // Clear the queue when exiting the program
            taskQueue.Clear();
        }
    }
}
