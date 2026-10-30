package com.example.quan_ly_xe.modules.vanhanh_b.controller;

import com.example.quan_ly_xe.common.exception.AppException;
import com.example.quan_ly_xe.common.exception.ErrorCode;
import com.example.quan_ly_xe.common.exception.GlobalExceptionHandler;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TripResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TicketResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.service.TicketService;
import com.example.quan_ly_xe.modules.vanhanh_b.service.TripService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.setup.MockMvcBuilders.standaloneSetup;

@ExtendWith(MockitoExtension.class)
class VanHanhControllerTest {
    @Mock private TripService tripService;
    @Mock private TicketService ticketService;
    private LocalValidatorFactoryBean validator;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();
        mockMvc = standaloneSetup(new TripController(tripService), new TicketController(ticketService))
                .setControllerAdvice(new GlobalExceptionHandler())
                .setValidator(validator)
                .build();
    }

    @AfterEach
    void tearDown() {
        validator.close();
    }

    @Test
    void findAll_wrapsResultInSuccessEnvelope() throws Exception {
        when(tripService.findAll(null, null, null, null)).thenReturn(
                List.of(TripResponse.builder().maChuyen("C261030001").build()));

        mockMvc.perform(get("/api/v1/vanhanh/chuyen-xe"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].maChuyen").value("C261030001"));
    }

    @Test
    void create_invalidBody_returnsE01AndFieldDetails() throws Exception {
        mockMvc.perform(post("/api/v1/vanhanh/chuyen-xe")
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("E01"))
                .andExpect(jsonPath("$.error.details").isArray())
                .andExpect(jsonPath("$.error.details[0].field").exists());
    }

    @Test
    void serviceAppException_returnsItsStatusAndCode() throws Exception {
        when(ticketService.cancel("VE001")).thenThrow(new AppException(ErrorCode.E24));

        mockMvc.perform(post("/api/v1/vanhanh/ve/VE001/huy"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("E24"));
    }

    @Test
    void findTicketsByTrip_wrapsResultInSuccessEnvelope() throws Exception {
        when(ticketService.findByTrip("C261030001")).thenReturn(List.of(
                TicketResponse.builder().maVe("VE001").soGhe(3).lanBan(1)
                        .hoTen("Nguyen Van A").soDienThoai("0901234567")
                        .trangThai("DaBan").build()));

        mockMvc.perform(get("/api/v1/vanhanh/chuyen-xe/C261030001/ve"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].maVe").value("VE001"))
                .andExpect(jsonPath("$.data[0].soGhe").value(3))
                .andExpect(jsonPath("$.data[0].lanBan").value(1))
                .andExpect(jsonPath("$.data[0].trangThai").value("DaBan"));
    }
}
