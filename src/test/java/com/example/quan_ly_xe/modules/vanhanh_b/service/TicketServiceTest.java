package com.example.quan_ly_xe.modules.vanhanh_b.service;

import com.example.quan_ly_xe.common.exception.AppException;
import com.example.quan_ly_xe.common.exception.ErrorCode;
import com.example.quan_ly_xe.common.exception.ResourceNotFoundException;
import com.example.quan_ly_xe.common.security.CurrentUser;
import com.example.quan_ly_xe.common.security.CurrentUserProvider;
import com.example.quan_ly_xe.common.security.Role;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.request.SellTicketRequest;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.SellTicketResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.dto.response.TicketResponse;
import com.example.quan_ly_xe.modules.vanhanh_b.repository.TicketSpRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TicketServiceTest {
    @Mock private TicketSpRepository repository;
    @Mock private CurrentUserProvider currentUserProvider;
    private TicketService service;

    @BeforeEach
    void setUp() {
        service = new TicketService(repository, currentUserProvider);
    }

    @Test
    void sell_invalidPhone_throwsE23() {
        SellTicketRequest request = validRequest();
        request.setSoDienThoai("123");

        AppException ex = assertThrows(AppException.class, () -> service.sell(request));

        assertEquals(ErrorCode.E23, ex.getErrorCode());
        verifyNoInteractions(repository, currentUserProvider);
    }

    @Test
    void sell_missingSeat_throwsE22() {
        SellTicketRequest request = validRequest();
        request.setSoGhe(null);

        AppException ex = assertThrows(AppException.class, () -> service.sell(request));

        assertEquals(ErrorCode.E22, ex.getErrorCode());
        verifyNoInteractions(repository, currentUserProvider);
    }

    @Test
    void sell_usesCurrentEmployeeCode() {
        SellTicketRequest request = validRequest();
        SellTicketResponse expected = SellTicketResponse.builder().maVe("VE001").lanBan(1).build();
        when(currentUserProvider.get()).thenReturn(
                new CurrentUser("NV0001", "Nhan vien", Role.NV_BAN_VE, "CN01"));
        when(repository.sell(request, "NV0001")).thenReturn(Optional.of(expected));

        SellTicketResponse actual = service.sell(request);

        assertEquals(expected, actual);
        verify(repository).sell(request, "NV0001");
    }

    @Test
    void findByPhone_blankValue_returnsEmptyWithoutRepositoryCall() {
        List<?> result = service.findByPhone("  ");

        assertTrue(result.isEmpty());
        verify(repository, never()).findByPhone("  ");
    }

    @Test
    void findByTrip_missingTrip_throwsNotFound() {
        when(repository.tripExists("C404")).thenReturn(false);

        assertThrows(ResourceNotFoundException.class, () -> service.findByTrip("C404"));

        verify(repository, never()).findByTrip("C404");
    }

    @Test
    void findByTrip_existingTripWithoutTickets_returnsEmptyList() {
        when(repository.tripExists("C261030001")).thenReturn(true);
        when(repository.findByTrip("C261030001")).thenReturn(List.of());

        assertTrue(service.findByTrip("C261030001").isEmpty());
    }

    @Test
    void findByTrip_withTickets_returnsMappedTickets() {
        TicketResponse expected = TicketResponse.builder().maVe("VE001").soGhe(3).lanBan(2)
                .hoTen("Nguyen Van A").soDienThoai("0901234567").trangThai("DaBan").build();
        when(repository.tripExists("C261030001")).thenReturn(true);
        when(repository.findByTrip("C261030001")).thenReturn(List.of(expected));

        List<TicketResponse> actual = service.findByTrip("C261030001");

        assertEquals(1, actual.size());
        assertEquals(expected, actual.get(0));
    }

    private SellTicketRequest validRequest() {
        return SellTicketRequest.builder().maChuyen("C261030001").soGhe(3)
                .hoTen("Nguyen Van A").soDienThoai("0901234567").build();
    }
}
