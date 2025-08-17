import xmlrpc.client
import time
import sys

if __name__ == "__main__":
    try:
        with xmlrpc.client.ServerProxy("http://localhost:9005/RPC2") as server:
            info = server.supervisor.getAllProcessInfo()
            error_states = list(filter(lambda x: x["state"] != 20, info))
            if error_states:
                print(f"Unhealthy processes: {[p['name'] for p in error_states]}")
                exit(1)
            else:
                print("All processes healthy")
                exit(0)
    except ConnectionRefusedError:
        print("Supervisor not ready yet")
        exit(1)
    except Exception as e:
        print(f"Health check error: {e}")
        exit(1)
