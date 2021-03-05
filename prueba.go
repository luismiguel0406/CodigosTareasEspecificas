package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strconv"
	//"time"
	"image"
	"image/jpeg"
	"bytes"

		
)

// A Response struct to map the Entire Response
type Response struct {
    Title    string    `json:"title"`
    //Pokemon []Pokemon `json:"pokemon_entries"`
}

func serveFrames(imgByte []byte) {

    img, _, err := image.Decode(bytes.NewReader(imgByte))
    if err != nil {
        log.Fatalln(err)
    }

    out, _ := os.Create("./Imagenes/img.jpeg")
    defer out.Close()

    var opts jpeg.Options
    opts.Quality = 1

    err = jpeg.Encode(out, img, &opts)
    //jpeg.Encode(out, img, nil)
    if err != nil {
        log.Println(err)
    }

}

func get(num int){
	//tr := &http.Transport{
	//	MaxIdleConns:       5000,
	//	IdleConnTimeout:    120* time.Second,
	//	DisableCompression: true,}

	//client:= &http.Client{Transport: tr}

	res, err := http.Get("https://jsonplaceholder.typicode.com/photos/"+ strconv.Itoa(num))
    if err != nil {
        fmt.Print(err.Error())
        os.Exit(1)
    }

	//req.Header.Add("Accept","application/json")
	//req.Header.Add("Content-Type", "application/json")

	//res, err:=client.Do(req)
   if err != nil{
   fmt.Println(err.Error())
}
    defer res.Body.Close()
   
    if err != nil {
        log.Fatal(err)
    }
	
    bodyBytes,err := ioutil.ReadAll(res.Body)
	if err != nil{
		fmt.Println(err.Error())
	 }


    var responseObject Response
    json.Unmarshal(bodyBytes, &responseObject)
	
    fmt.Println(strconv.Itoa(num) +" "+ responseObject.Title)
 	
}


func (t Response) toString() string {
    bytes, err := json.Marshal(t)
    if err != nil {
        fmt.Println(err.Error())
        os.Exit(1)
    }
    return string(bytes)
}

func getPhotos() []Response {
    datos := make([]Response,0)
    raw, err := ioutil.ReadFile("./photos.json")
    if err != nil {
        fmt.Println(err.Error())
        os.Exit(1)
    }
    json.Unmarshal(raw, &datos)
    return datos
}

func funcion() {
    fotos := getPhotos()
    fmt.Println(fotos)
    for _, pic := range fotos {
        fmt.Println(pic.toString())
		//pic.toString()
        //fmt.Println(strconv.Itoa(contador))
		
    }
}

func main() {
//for i := 1; i < 5000; i++{
  // go get(i)
  //} 
 go funcion()
 
 var s string
 fmt.Scan(&s)
}
