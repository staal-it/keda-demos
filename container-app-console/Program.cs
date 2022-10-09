using System;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using Microsoft.Azure.Storage;
using Microsoft.Azure.Storage.Queue;

namespace consolejob
{
    class Program
    {
        static void Main(string[] args)
        {
            new Thread(StartHealthProbe).Start();

            Thread.Sleep(5000);

            CloudQueue queue = CreateQueueClient();

            while (true)
            {
                CloudQueueMessage retrievedMessage = queue.GetMessage();

                if (retrievedMessage != null)
                {
                    Console.WriteLine($"The message in the queue: {retrievedMessage.AsString}");

                    queue.DeleteMessage(retrievedMessage);
                }
                else
                {
                    Console.WriteLine($"No messages on the Queue, sleeping...");
                    Thread.Sleep(3000);
                }
            }
        }

        private static CloudQueue CreateQueueClient()
        {
            var storageConnectionString = Environment.GetEnvironmentVariable("QUEUECONNECTIONSTRING");
            var queueName = Environment.GetEnvironmentVariable("QUEUENAME");

            CloudStorageAccount storageAccount = CloudStorageAccount.Parse(storageConnectionString);

            CloudQueueClient queueClient = storageAccount.CreateCloudQueueClient();

            return queueClient.GetQueueReference(queueName);
        }

        private static void StartHealthProbe()
        {
            TcpListener server = null;
            try
            {
                server = new TcpListener(IPAddress.Any, 3000);

                server.Start();
                Console.WriteLine("Server Started");

                while (true)
                {
                    Console.WriteLine("Waiting for a connection... ");
                    TcpClient client = server.AcceptTcpClient();
                    Console.WriteLine("Connected!");
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
            }
        }
    }
}