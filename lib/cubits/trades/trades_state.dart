import 'package:equatable/equatable.dart';
import '../../models/trade.dart';

abstract class TradesState extends Equatable {
  const TradesState();

  @override
  List<Object?> get props => [];
}

class TradesInitial extends TradesState {
  const TradesInitial();
}

class TradesLoading extends TradesState {
  const TradesLoading();
}

class TradesLoaded extends TradesState {
  final List<Trade> trades;

  const TradesLoaded(this.trades);

  @override
  List<Object?> get props => [trades];
}

class TradesError extends TradesState {
  final String message;

  const TradesError(this.message);

  @override
  List<Object?> get props => [message];
}
