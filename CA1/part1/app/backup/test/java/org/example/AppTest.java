package org.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class AppTest {
    @Test
    void greetingIsNotNull() {
        assertNotNull(new App().getGreeting());
    }

    @Test
    void greetingMentionsTheApplicationName() {
        assertTrue(new App().getGreeting().contains("Multi-User Chat Application"));
    }
}