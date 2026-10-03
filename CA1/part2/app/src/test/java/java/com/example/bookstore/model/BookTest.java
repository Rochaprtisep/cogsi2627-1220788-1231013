package com.example.bookstore.model;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class BookTest {

    @Test
    void newBookHasNoId() {
        assertNull(new Book().getId());
    }

    @Test
    void settersAndGettersKeepValues() {
        Book book = new Book();
        book.setTitle("The 48 Laws of Power");
        book.setAuthor("Robert Greene");
        book.setPrice(20.50);

        assertEquals("The 48 Laws of Power", book.getTitle());
        assertEquals("Robert Greene", book.getAuthor());
        assertEquals(20.50, book.getPrice());
    }
}