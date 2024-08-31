import socket
import json
from _thread import start_new_thread


clients = "AB"
clients_conn = []
i = 0

A_ships = []
B_ships = []

A_hit_state = [0]*64
B_hit_state = [0]*64



def handle_client(conn):
    global i
    conn.sendall((json.dumps({"status": "connected", "client": clients[i]})).encode('utf-8') )
    c_name = clients[i]
    reply = {}
    j = 0
    print("Client connected: ", c_name)
    i = (i+1) % 2
    while True:
        print("iteration:", j)
        try:
            data = conn.recv(2048).decode('utf-8')
            if not data:
                print(c_name, "disconnected")
                clients_conn.remove(conn)
                break

            print("Received:",  fr'{data}')
            try:
                data = json.loads(data)
            except json.JSONDecodeError:
                continue
            
            if data.get('type') == "init":
                reply = handle_start_game(data)
            elif data.get('type') == "game":
                reply = handle_game_loop(data, conn)
            else:
                reply = {'type': 'error', 'message': 'invalid request'}
            
            conn.sendall(json.dumps(reply).encode('utf-8'))
        except socket.error as e:
            print(e)
            break
        j += 1

def handle_start_game(data: dict) -> dict:
    global A_ships, B_ships
    print(data)
    if data["client"] == "A":
        A_ships = data["ships"]
    else:
        B_ships = data["ships"]
    return {'type': 'reply'}

def handle_game_loop(data: dict, conn) -> dict:
    global A_ships, B_ships
    target = data['pos']

    state = B_hit_state if data["client"] == "A" else A_hit_state
     # attacked state of A if B is attacking and vice versa

    for other in clients_conn:
        if conn != other:
            other.sendall(json.dumps({"type": "update", "state":state}).encode('utf-8'))  # send state to other client to update their board

    return {'type': 'reply', "state": state} # send state to client to update that hit or miss

    



def start_server(host='127.0.0.1', port=65432):
    global clients_conn
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((host, port))
    server_socket.listen(1)
    server_socket.settimeout(0.5) # timeout listener every 0.5 seconds, allows for keyboard interrupt
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)  

    print(f"Server listening on {host}:{port}...")

    while True:
        try:
            conn, addr = server_socket.accept()
            clients_conn.append(conn)
        except socket.timeout:
            continue

        print(f"Connected by {addr}")
        start_new_thread(handle_client, (conn, ))
        


if __name__ == "__main__":
    start_server()
