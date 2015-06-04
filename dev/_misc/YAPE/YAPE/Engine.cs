using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace YAPE
{
    public class Engine
    {
        private enum ExitState { NORMAL, ERROR, CANCEL }

        ExitState exitState;

        TaskScheduler scheduler;
        CancellationTokenSource tokenSource;

        public event EventHandler OnFinish;
        public event EventHandler OnCancel;
        public event EventHandler OnError;

        public Engine()
        {
            scheduler = TaskScheduler.FromCurrentSynchronizationContext();
            tokenSource = new CancellationTokenSource();
        }

        public void CancelAsync()
        {
            exitState = ExitState.CANCEL;
            tokenSource.Cancel();
        }

        public void DoWorkAsync(IActionProvider provider)
        {
            exitState = ExitState.NORMAL;
            CancellationToken token = tokenSource.Token;

            Task mainTask = Task.Factory.StartNew(() =>
            {
                while (true)
                {
                    if (token.IsCancellationRequested) break;
                    try
                    {
                        Action[] actions = provider.GetActions();
                        if (actions.Length == 0) break;
                        List<Task> tasks = new List<Task>();
                        foreach (Action action in actions)
                        {
                            if (token.IsCancellationRequested) break;
                            try
                            {
                                Task subtask = Task.Factory.StartNew(action, token);
                                subtask.ContinueWith(TaskFailed, TaskContinuationOptions.OnlyOnFaulted);
                                tasks.Add(subtask);
                            }
                            catch
                            {
                                exitState = ExitState.ERROR;
                                tokenSource.Cancel();
                                break;
                            }
                        }
                        try
                        {
                            Task.WaitAll(tasks.ToArray(), tokenSource.Token);
                        }
                        catch (OperationCanceledException){}
                    }
                    catch
                    {
                        exitState = ExitState.ERROR;
                        break;
                    }
                }
            }, TaskCreationOptions.LongRunning);
            mainTask.ContinueWith(Done, scheduler);
        }

        public void DoWorkAsync(Action<Object> workAction, IArgumentProvider provider)
        {
            exitState = ExitState.NORMAL;
            CancellationToken token = tokenSource.Token;

            Task mainTask = Task.Factory.StartNew(() =>
            {
                while (true)
                {
                    if (token.IsCancellationRequested) break;
                    try
                    {
                        Object[] args = provider.GetArguments();
                        if (args.Length == 0) break;
                        List<Task> tasks = new List<Task>();
                        foreach (Object arg in args)
                        {
                            if (token.IsCancellationRequested) break;
                            try
                            {
                                Task subtask = Task.Factory.StartNew(workAction, arg, token);
                                subtask.ContinueWith(TaskFailed, TaskContinuationOptions.OnlyOnFaulted);
                                tasks.Add(subtask);
                            }
                            catch
                            {
                                exitState = ExitState.ERROR;
                                tokenSource.Cancel();
                                break;
                            }
                        }
                        try
                        {
                            Task.WaitAll(tasks.ToArray(), tokenSource.Token);
                        }
                        catch (OperationCanceledException) { }
                    }
                    catch
                    {
                        exitState = ExitState.ERROR;
                        break;
                    }
                }
            }, TaskCreationOptions.LongRunning);
            mainTask.ContinueWith(Done, scheduler);
        }

        void TaskFailed(Task tast)
        {
            exitState = ExitState.ERROR;
            tokenSource.Cancel();
        }

        void FireEvent(EventHandler handler)
        {
            if (handler != null) handler(this, EventArgs.Empty);
        }

        void Done(Task t)
        {
            switch (exitState)
            {
                case ExitState.NORMAL:
                    FireEvent(OnFinish);
                    break;
                case ExitState.ERROR:
                    FireEvent(OnError);
                    break;
                case ExitState.CANCEL:
                    FireEvent(OnCancel);
                    break;
            }
        }

    }
}
