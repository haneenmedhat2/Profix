#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/profix-contract-checks.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc \
  -module-cache-path "$test_dir/module-cache" \
  Profix/App/Orders/OrderDetails/Model/PaymentCountdownState.swift \
  Profix/Networking/BaseResponse/BaseResponse.swift \
  Profix/Networking/BaseResponse/ServerResponseKey.swift \
  Tests/UserAppContractChecks.swift \
  -o "$test_dir/checks"
"$test_dir/checks"
xcrun swiftc \
  -module-cache-path "$test_dir/module-cache" \
  Profix/App/Orders/OrderDetails/Model/PaymentCountdownState.swift \
  Profix/Networking/BaseResponse/BaseResponse.swift \
  Profix/Networking/BaseResponse/ServerResponseKey.swift \
  Profix/Shared/Helper/Analytics/OrderAnalytics.swift \
  Profix/Shared/Helper/PaymentCompletionHandler.swift \
  Profix/App/Orders/OrderDetails/Model/PaymentMethods.swift \
  Profix/Networking/HandelRequest/UploadData.swift \
  Profix/App/Home/OrderSummary/Model/CreateOrderModel.swift \
  Profix/App/Home/OrderSummary/ViewModel/OrderSummaryVM.swift \
  Profix/App/Orders/OrderDetails/ViewModel/OrderDetailsVM.swift \
  Tests/OrderDetailsVMChecks.swift \
  Tests/OrderAnalyticsChecks.swift \
  -o "$test_dir/viewmodel-checks"
"$test_dir/viewmodel-checks"
xcrun swiftc \
  -module-cache-path "$test_dir/module-cache" \
  Profix/App/Home/ProviderDetails/Model/ProviderDayPeriods.swift \
  Profix/App/Home/ProviderDetails/Model/AllDelegateResponse.swift \
  Profix/App/Home/MainCategory/Model/MainCategoryModel.swift \
  Profix/App/Home/Services/Model/Services.swift \
  Profix/Networking/BaseResponse/BaseResponse.swift \
  Profix/Networking/BaseResponse/ServerResponseKey.swift \
  Profix/Shared/View/TimePicker/BookingTimeSelection.swift \
  Profix/Shared/View/TimePicker/BookingClockSelection.swift \
  Tests/ProviderAvailabilityChecks.swift \
  -o "$test_dir/availability-checks"
"$test_dir/availability-checks"
