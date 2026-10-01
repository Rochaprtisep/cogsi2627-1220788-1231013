package com.example.bookstore.model;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ClientTest {

    @Test
    void validNifIsStored() {
        Client client = new Client();
        client.setNif(123456789);
        assertEquals(123456789, client.getNif());
    }

    @Test
    void nifBelowNineDigitsIsRejected() {
        Client client = new Client();
        assertThrows(IllegalArgumentException.class, () -> client.setNif(12345));
    }

    @Test
    void nifAboveNineDigitsIsRejected() {
        Client client = new Client();
        assertThrows(IllegalArgumentException.class, () -> client.setNif(1234567890));
    }
}