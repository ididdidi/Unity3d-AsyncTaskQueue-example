using System.Threading;
using System.Threading.Tasks;
using UnityEngine;
using ru.mofrison.AsyncTasks;

namespace ru.mofrison.Unity3d
{
    public class AsyncTaskManager : MonoBehaviour
    {
        private readonly AsyncTaskQueue taskQueue = new AsyncTaskQueue(2);
        private int N = 0;

        // Start is called before the first frame update
        async void Start()
        {
            // Add tasks to the queue 
            taskQueue.Add((cancellationToken) => TestTask(cancellationToken, 1));
            taskQueue.Add((cancellationToken) => TestTask(cancellationToken, 2));
            taskQueue.Add((cancellationToken) => TestTask(cancellationToken, 3), AsyncTask.Priority.High);
            taskQueue.Add((cancellationToken) => TestTask(cancellationToken, 4));
            taskQueue.Add((cancellationToken) => TestTask(cancellationToken, 5), AsyncTask.Priority.Interrupt);

            // Take the first task and start the loop until all tasks in the queue are completed 
            var asyncTask = taskQueue.GetNext();
            while (asyncTask != null)
            {
                await asyncTask.Run();
                try
                {
                    // Retrieve the next item and repeat the loop
                    asyncTask = taskQueue.GetNext();
                }
                catch (AsyncTaskQueue.Exception e) 
                {
                    Debug.LogError(e.Message);
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

                if (taskQueue.NextIsRedy)
                {
                    // Run the added task, if possible
                    taskQueue.GetNext().Run();
                }
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
