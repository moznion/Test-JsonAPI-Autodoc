generated at: 2013-11-04 22:41:10

## POST /

get message ok

### Target Server

http://localhost

(Plack application)

### Parameters

__application/json__

- `jsonrpc`: Number (e.g. 2.0)
- `method`: String (e.g. "get_entries")
- `params`: JSON
    - `category`: String (e.g. "technology")
    - `limit`: Number (e.g. 1)

### Request

POST /

### Response

```
Status:       200
Content-Type: application/json
Response:
{
   "jsonrpc" : "2.0",
   "id" : 1,
   "result" : {
      "entries" : [
         {
            "body" : "Hello!",
            "title" : "example"
         }
      ]
   }
}

```

