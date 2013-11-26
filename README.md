wrinqle
======
###Goal

The goal of wrinqle is to provide an easy way to facilitate communication between web sockets connected to the same server. 

### How does this work?

* Each websocket is 'registered' with a name. 

```
socket.send(JSON.stringify({"register":name}));
```

Now just send message to the registered channel

```
socket.send(JSON.stringify({"to":["name1","name2"],"msg":"Hello"}));
```

You can also do pub/sub

**SUB**
```
socket.send(JSON.stringify({"subscribe":["name1","name2"],"to":"name3"}));


```

**PUB**
```
socket.send(JSON.stringify({"publish":"Publish message from name3","to":"name3"}));


```
To recieve messages just use the vanilla socket api
```
socket.onmessage= function(event){
	data = event.data;
}
```


There is no client side library. Use the web sockets like you do normally.  


### TODO

1. Write unit tests for the gen_events
2. Provide pusher like channel authentication using a key.
3. Document server response to `socket.send()` (this is changing constantly and I will add it to the readme once I finalize it)
4. Provide a tutorial on hacking wrinqle from erlang
