; Marius-Mihail Gurgu, Alexandre Thomas Janin, Wei-Heng Ke

.data

N_COEFFS: .word	3 
coeff:     .double -0.5, -1.0, -0.5
N_SAMPLES: .word 10
sample:    .double 0.0, 1.0, 0.0, 1.0, 2.0, 0.0, 1.0, -2.0, 3.0, 0.0
result:    .double 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

.text

main:
      ld $s0, N_SAMPLES($0)
	  ld $t1, N_COEFFS($0)
	  daddi $s1, $zero, sample ; s1 = &sample[0]
	  daddi $s2, $zero, result ; s2 = &result[0]
	  mtc1 $zero, f0 ; make f0 zero
	  slt $t2,$s0,$t1	; t2 = N_SAMPLES < N_COEFFS 
	  ;if dunno what to do, just call daddi
	  daddi $s4, $zero, coeff ; s4 = &coeff[0]
	  l.d f8, 0($s4)  		; f8 = coeff[0]
	  l.d f9, 8($s4)		; f9 = coeff[1]
	  l.d f10, 16($s4)		; f10 = coeff[2]
	  dadd $t1, $zero, $zero  ; make t1 zero
	  
	  bne  $t2,$0, end	; if slt condition true then end program	  
	  
	  
	  l.d f1, 8($t1)
	  l.d f2, 0($s4)
	  

	 ;Compute norm
	 daddi $t7, $zero, -1 ;maybe combine these 2 instructions
	 dsrl $t7, $t7, 1 ;shift right logical by 1 bit
	 ld $t6, ($s4) ;t6 = coeff[0]
	 ld $t5, 8($s4) ;t5 = coeff[1]
	 and $t6, $t6, $t7
	 mtc1 $t6, f0
	 and $t5, $t5, $t7
	 mtc1 $t5, f1
	 add.d f0, f0, f1 ;can you avoid structural stall here?
	 ld $t4, 16($s4)
	 and $t4, $t4, $t7
	 mtc1 $t4, f2	 
	 add.d f0, f0, f2 ; f0 = norm
	
	; daddi $s3, $s0, -1
	; dsll $t0, $s3, 3
	; dadd $t1, $t0, $s1
	; l.d f3, 0($t1)
	; dadd $t2, $t0, $s2
	; s.d f3, 0($t2)
	; l.d f4, 0($t2)
	

		;Loop 
		
	daddi $s3, $s0, -2
	dsll $t0, $s3, 3   ; $t0 = 8 * (N_SAMPLES - 2)
	dadd $t1, $t0, $s1 ; $t1 = &sample[N_SAMPLES - 2]

	l.d f20, 0($s1)

for:	l.d f11, 0($s1) ; f11 = sample[i - 1]
		l.d f12, 8($s1) ; f12 = sample[i]
		mul.d f14, f11, f8
		mul.d f15, f12, f9
		l.d f13, 16($s1) ; f13 = sample[i+1]
		mul.d f16, f13, f10
		add.d f19, f14, f15
		daddi $s1, $s1, 8
		daddi $s2, $s2, 8
		add.d f19, f19, f16
		s.d f20, -8($s2)
		
		bne $s1, $t1, for ; if (sample != &sample[N_SAMPLES - 2]) goto for;
	    div.d f20, f19, f0
		
	s.d f20, 0($s2)
	l.d f20, 8($s1)
	s.d f20, 8($s2)
		



end:  halt     
