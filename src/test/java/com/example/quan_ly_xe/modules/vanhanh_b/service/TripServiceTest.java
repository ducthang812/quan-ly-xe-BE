package com.example.quan_ly_xe.modules.vanhanh_b.service;

import com.example.quan_ly_xe.common.exception.AppException;
import com.example.quan_ly_xe.common.exception.ErrorCode;
import com.example.quan_ly_xe.common.exception.ResourceNotFoundException;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.CreateTripRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.FinishTripRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.repository.TripSpRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TripServiceTest {
    @Mock private TripSpRepository repository;
    private TripService service;

    @BeforeEach
    void setUp() {
        service = new TripService(repository);
    }

    @Test
    void create_sameDriverAndAssistant_throwsE14WithoutCallingRepository() {
        CreateTripRequest request = CreateTripRequest.builder().maLai("TX0001").maPhu("TX0001").build();

        AppException ex = assertThrows(AppException.class, () -> service.create(request));

        assertEquals(ErrorCode.E14, ex.getErrorCode());
        verify(repository, never()).create(request);
    }

    @Test
    void finish_nonPositiveDistance_throwsE21WithoutCallingRepository() {
        FinishTripRequest request = FinishTripRequest.builder()
                .kmThucTe(0).chiPhiVanHanh(BigDecimal.ZERO).build();

        AppException ex = assertThrows(AppException.class, () -> service.finish("C261030001", request));

        assertEquals(ErrorCode.E21, ex.getErrorCode());
        verify(repository, never()).finish("C261030001", request);
    }

    @Test
    void finish_negativeOperatingCost_throwsE31WithoutCallingRepository() {
        FinishTripRequest request = FinishTripRequest.builder()
                .kmThucTe(100).chiPhiVanHanh(BigDecimal.valueOf(-1)).build();

        AppException ex = assertThrows(AppException.class, () -> service.finish("C261030001", request));

        assertEquals(ErrorCode.E31, ex.getErrorCode());
        verify(repository, never()).finish("C261030001", request);
    }

    @Test
    void findById_missingTrip_throwsNotFound() {
        when(repository.findById("UNKNOWN")).thenReturn(Optional.empty());

        ResourceNotFoundException ex = assertThrows(ResourceNotFoundException.class,
                () -> service.findById("UNKNOWN"));

        assertEquals(ErrorCode.NOT_FOUND, ex.getErrorCode());
    }
}
