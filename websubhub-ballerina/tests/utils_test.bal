// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/mime;
import ballerina/http;

@test:Config { 
    groups: ["contentTypeRetrieval"]
}
function testContentTypeRetrievalForString() returns @tainted error? {
    string contentType = retrieveContentType((), "This is sample content delivery");
    test:assertEquals(contentType, mime:TEXT_PLAIN);
}

@test:Config { 
    groups: ["contentTypeRetrieval"]
}
function testContentTypeRetrievalForXml() returns @tainted error? {
    xml content = xml `<content>
        <contentUrl>The Lost World</contentUrl>
        <contentMsg>Enjoy free offers this season</contentMsg>
    </content>`;
    string contentType = retrieveContentType((), content);
    test:assertEquals(contentType, mime:APPLICATION_XML);
}

@test:Config { 
    groups: ["contentTypeRetrieval"]
}
function testContentTypeRetrievalForJson() returns @tainted error? {
    json content = {
        contentUrl: "https://sample.content.com",
        contentMsg: "Enjoy free offers this season"
    };
    string contentType = retrieveContentType((), content);
    test:assertEquals(contentType, mime:APPLICATION_JSON);
}

@test:Config { 
    groups: ["contentTypeRetrieval"]
}
function testContentTypeRetrievalForFormUrlEncoded() returns @tainted error? {
    map<string> content = {
        contentUrl: "https://sample.content.com",
        contentMsg: "Enjoy free offers this season"
    };
    string contentType = retrieveContentType((), content);
    test:assertEquals(contentType, mime:APPLICATION_FORM_URLENCODED);
}

@test:Config { 
    groups: ["contentTypeRetrieval"]
}
function testContentTypeRetrievalForByteArray() returns @tainted error? {
    byte[] content = "This is sample content delivery".toBytes();
    string contentType = retrieveContentType((), content);
    test:assertEquals(contentType, mime:APPLICATION_OCTET_STREAM);
}

const string HASH_KEY = "secret";

@test:Config { 
    groups: ["contentSignature"]
}
function testStringContentSignature() returns @tainted error? {
    string content = "This is sample content delivery";
    byte[] hashedContent = check retrievePayloadSignature(HASH_KEY, content);
    test:assertEquals("d66181d67f963fff2dde0b0a4ca50ac1a6bc5828dd32eabaf0d5049f6fe8b5ff", hashedContent.toBase16());
}

@test:Config { 
    groups: ["contentSignature"]
}
function testXmlContentSignature() returns @tainted error? {
    xml content = xml `<content>
        <contentUrl>The Lost World</contentUrl>
        <contentMsg>Enjoy free offers this season</contentMsg>
    </content>`;
    byte[] hashedContent = check retrievePayloadSignature(HASH_KEY, content);
    test:assertEquals("526af3b9e1d8f5f618b06f88c9c142ef4baee4c66c16d4026d2307689643de58", hashedContent.toBase16());
}

@test:Config { 
    groups: ["contentSignature"]
}
function testJsonContentSignature() returns @tainted error? {
    json content = {
        contentUrl: "https://sample.content.com",
        contentMsg: "Enjoy free offers this season"
    };
    byte[] hashedContent = check retrievePayloadSignature(HASH_KEY, content);
    test:assertEquals("a67cf8d3245fb03dd7914097bb731cc7532ff7c8bb738c2a587506b0bc4c0dda", hashedContent.toBase16());
}

@test:Config { 
    groups: ["contentSignature"]
}
function testFormUrlEncodedContentSignature() returns @tainted error? {
    map<string> content = {
        contentUrl: "https://sample.content.com",
        contentMsg: "Enjoy free offers this season"
    };
    byte[] hashedContent = check retrievePayloadSignature(HASH_KEY, content);
    test:assertEquals("a67cf8d3245fb03dd7914097bb731cc7532ff7c8bb738c2a587506b0bc4c0dda", hashedContent.toBase16());
}

@test:Config { 
    groups: ["contentSignature"]
}
function testByteArrayContentSignature() returns @tainted error? {
    byte[] content = "This is sample content delivery".toBytes();
    byte[] hashedContent = check retrievePayloadSignature(HASH_KEY, content);
    test:assertEquals("d66181d67f963fff2dde0b0a4ca50ac1a6bc5828dd32eabaf0d5049f6fe8b5ff", hashedContent.toBase16());
}


http:Client headerRetrievalTestingClient = checkpanic new ("http://localhost:9191/subscriber");

@test:Config { 
    groups: ["clientResponseHeaderRetrieval"]
}
function testResponseHeaderRetrievalWithManuallyCreatingHeaders() returns @tainted error? {
    http:Response response = new;
    foreach var [header, value] in CUSTOM_HEADERS.entries() {
        if (value is string) {
            response.setHeader(header, value);
        } else {
            foreach var val in value {
                response.addHeader(header, val);
            }
        }
    }

    map<string|string[]> retrievedResponseHeaders = check retrieveResponseHeaders(response);
    test:assertTrue(retrievedResponseHeaders.length() > 0);
    boolean isSuccess = check hasAllHeaders(retrievedResponseHeaders);
    test:assertTrue(isSuccess);
}

@test:Config { 
    groups: ["clientResponseHeaderRetrieval"]
}
function testResponseHeaderRetrievalWithApiCall() returns @tainted error? {
    http:Request request = new;
    http:Response retrievedResponse = check headerRetrievalTestingClient->post("/addHeaders", request);
    map<string|string[]> retrievedResponseHeaders = check retrieveResponseHeaders(retrievedResponse);
    test:assertTrue(retrievedResponseHeaders.length() > 0);
    boolean isSuccess = check hasAllHeaders(retrievedResponseHeaders);
    test:assertTrue(isSuccess);
}

@test:Config { 
    groups: ["clientResponseBodyRetrieval"]
}
function testResponsePayloadRetrievalForText() returns @tainted error? {
    http:Request request = new;
    request.setTextPayload("text");
    http:Response retrievedResponse = check headerRetrievalTestingClient->post("/addPayload", request);
    string|byte[]|json|xml|map<string> responseBody = check retrieveResponseBody(retrievedResponse);
    test:assertTrue(responseBody is string);
    test:assertEquals(responseBody, "This is a test message");
}

@test:Config { 
    groups: ["clientResponseBodyRetrieval"]
}
function testResponsePayloadRetrievalForJson() returns @tainted error? {
    http:Request request = new;
    request.setTextPayload("json");
    json expectedPayload = {
                    "message": "This is a test message"
    };
    http:Response retrievedResponse = check headerRetrievalTestingClient->post("/addPayload", request);
    string|byte[]|json|xml|map<string> responseBody = check retrieveResponseBody(retrievedResponse);
    test:assertTrue(responseBody is json);
    test:assertEquals(responseBody, expectedPayload);
}

@test:Config { 
    groups: ["clientResponseBodyRetrieval"]
}
function testResponsePayloadRetrievalForXml() returns @tainted error? {
    http:Request request = new;
    request.setTextPayload("xml");
    xml expectedPayload = xml `<content><message>This is a test message</message></content>`;
    http:Response retrievedResponse = check headerRetrievalTestingClient->post("/addPayload", request);
    string|byte[]|json|xml|map<string> responseBody = check retrieveResponseBody(retrievedResponse);
    test:assertTrue(responseBody is xml);
    test:assertEquals(responseBody, expectedPayload);
}

@test:Config { 
    groups: ["clientResponseBodyRetrieval"]
}
function testResponsePayloadRetrievalForBteArray() returns @tainted error? {
    http:Request request = new;
    request.setTextPayload("byte");
    byte[] expectedPayload = "This is a test message".toBytes();
    http:Response retrievedResponse = check headerRetrievalTestingClient->post("/addPayload", request);
    string|byte[]|json|xml|map<string> responseBody = check retrieveResponseBody(retrievedResponse);
    test:assertTrue(responseBody is byte[]);
    test:assertEquals(responseBody, expectedPayload);
}

function hasAllHeaders(map<string|string[]> retrievedHeaders) returns boolean|error {
    foreach var [header, value] in CUSTOM_HEADERS.entries() {
        if (retrievedHeaders.hasKey(header)) {
            string|string[] retrievedValue = retrievedHeaders.get(header);
            if (retrievedValue is string) {
                if (value is string && retrievedValue != value) {
                    return false;
                }
                if (value is string[] && retrievedValue != value[0]) {
                    return false;
                }
            } else {
                if (value is string) {
                    return false;
                } else {
                    foreach var item in value {
                        if (retrievedValue.indexOf(item) is ()) {
                            return false;
                        }
                    }
                }
            }
        } else {
            return false;
        }
    }
    return true;
}
