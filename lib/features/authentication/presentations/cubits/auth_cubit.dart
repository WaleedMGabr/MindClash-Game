import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mindclash/features/authentication/domain/entities/user_entity.dart';
import 'package:mindclash/features/authentication/domain/use_cases/auth_usecases.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.signupUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(AuthInitial());

  Future<void> checkAuthStatus() async{
    final result = await getCurrentUserUseCase.call();

    result.fold((failure)=> emit(Unauthenticated()), (user){
      if(user != null){
        emit(AuthSuccess(user));
      }else{
        emit(Unauthenticated());
      }
    });
  }

  Future<void> login({required String email, required String password,}) async {
    emit(AuthLoading());

    final result = await loginUseCase.call(email: email, password: password);
    result.fold(
      (failure) => emit(AuthError(failure.msg)),
      (user) => emit(AuthSuccess(user)),
    );
  }

  Future<void> signup({required String email, required String password, required String username}) async {
    emit(AuthLoading());
    final result =await signupUseCase.call(email: email, password: password, username: username);
    result.fold(
      (failure) {
        print("SIGNUP ERROR: ${failure.msg}");
        emit(AuthError(failure.msg));
      },
      (user) => emit(AuthSuccess(user)),
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    final result = await logoutUseCase.call();
    result.fold((failure)=> emit(AuthError(failure.msg)), (_)=> emit(Unauthenticated()));
  }


}

