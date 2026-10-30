package com.example.quan_ly_xe.common.exception;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockHttpServletRequest;

import java.sql.SQLException;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class GlobalExceptionHandlerTest {
    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @ParameterizedTest
    @MethodSource("moduleBSqlErrors")
    void sqlThrowCode_mapsToExpectedErrorAndHttpStatus(int sqlCode, ErrorCode expected) {
        SQLException sqlException = new SQLException(String.valueOf(sqlCode), "S0001", sqlCode);
        DataIntegrityViolationException exception = new DataIntegrityViolationException("stored procedure failed", sqlException);

        var response = handler.handleDataAccess(exception, request());

        assertEquals(expected.getHttpStatus(), response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(expected.name(), response.getBody().getError().getCode());
    }

    @Test
    void e19_fillsDriverCodeFromSqlMessage() {
        SQLException sqlException = new SQLException("50302|TX0001", "S0001", 50302);
        DataIntegrityViolationException exception = new DataIntegrityViolationException("stored procedure failed", sqlException);

        var response = handler.handleDataAccess(exception, request());

        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("E19", response.getBody().getError().getCode());
        assertTrue(response.getBody().getError().getMessage().contains("TX0001"));
        assertTrue(response.getBody().getError().getMessageEn().contains("TX0001"));
    }

    @Test
    void driverNotActive_fillsDriverCodeFromSqlMessage() {
        SQLException sqlException = new SQLException("50301|TX0001", "S0001", 50301);
        DataIntegrityViolationException exception = new DataIntegrityViolationException("stored procedure failed", sqlException);

        var response = handler.handleDataAccess(exception, request());

        assertEquals(HttpStatus.UNPROCESSABLE_CONTENT, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("DRIVER_NOT_ACTIVE", response.getBody().getError().getCode());
        assertTrue(response.getBody().getError().getMessage().contains("TX0001"));
        assertTrue(response.getBody().getError().getMessageEn().contains("TX0001"));
    }

    private static Stream<Arguments> moduleBSqlErrors() {
        return Stream.of(
                Arguments.of(50401, ErrorCode.E15), Arguments.of(50402, ErrorCode.E16),
                Arguments.of(50403, ErrorCode.E17), Arguments.of(50404, ErrorCode.E18),
                Arguments.of(50601, ErrorCode.E21), Arguments.of(51001, ErrorCode.E25),
                Arguments.of(51002, ErrorCode.E25), Arguments.of(51003, ErrorCode.E24),
                Arguments.of(53001, ErrorCode.E14),
                Arguments.of(50301, ErrorCode.DRIVER_NOT_ACTIVE),
                Arguments.of(54001, ErrorCode.TRIP_NOT_CANCELLABLE),
                Arguments.of(54002, ErrorCode.TICKET_ALREADY_CANCELLED),
                Arguments.of(54003, ErrorCode.TRIP_CODE_EXHAUSTED));
    }

    private MockHttpServletRequest request() {
        return new MockHttpServletRequest("POST", "/api/v1/vanhanh/test");
    }
}
