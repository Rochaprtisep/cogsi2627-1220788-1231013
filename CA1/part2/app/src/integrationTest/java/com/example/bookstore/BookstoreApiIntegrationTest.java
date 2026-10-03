package com.example.bookstore;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class BookstoreApiIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void booksEndpointReturnsSampleData() throws Exception {
        mockMvc.perform(get("/books"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Clean Code")));
    }

    @Test
    void infoDetailsExposesFilteredProperties() throws Exception {
        mockMvc.perform(get("/info/details"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("1.0.0")));
    }
}