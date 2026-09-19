import React, { createContext, useContext, useState, useEffect, useCallback } from "react";
import { apiRequest } from "../api/client.js";
import { useAuth } from "./AuthContext.js";

export interface SubscriptionPlan {
  id: string;
  name: string;
  code: "TRIAL" | "STARTER" | "PRO" | "ENTERPRISE";
  monthlyPrice: number;
  yearlyPrice: number;
  maxUsers: number;
  maxMedicines: number;
  maxInvoicesPerMonth: number;
  featuresJson?: string | null;
}

export interface ShopSubscription {
  id: string;
  planId: string;
  status: "TRIAL" | "ACTIVE" | "PAST_DUE" | "SUSPENDED" | "CANCELLED";
  billingCycle: "MONTHLY" | "YEARLY";
  startDate: string;
  endDate: string;
  plan: SubscriptionPlan;
}

export interface Shop {
  id: string;
  name: string;
  slug: string;
  ownerName: string;
  phone: string;
  email?: string | null;
  drugLicenseNo: string;
  gstin?: string | null;
  address: string;
  city: string;
  state: string;
  pincode: string;
  invoicePrefix: string;
  status: "ACTIVE" | "INACTIVE" | "SUSPENDED";
  createdAt: string;
  subscription?: ShopSubscription | null;
  _count?: {
    medicines?: number;
    salesInvoices?: number;
    customers?: number;
    members?: number;
  };
}

interface ShopContextType {
  shops: Shop[];
  currentShop: Shop | null;
  isLoading: boolean;
  setCurrentShop: (shop: Shop) => void;
  refreshShops: () => Promise<void>;
  isOnboardModalOpen: boolean;
  setIsOnboardModalOpen: (open: boolean) => void;
  isSubscriptionModalOpen: boolean;
  setIsSubscriptionModalOpen: (open: boolean) => void;
}

const ShopContext = createContext<ShopContextType | undefined>(undefined);

export const ShopProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated } = useAuth();
  const [shops, setShops] = useState<Shop[]>([]);
  const [currentShop, setCurrentShopState] = useState<Shop | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isOnboardModalOpen, setIsOnboardModalOpen] = useState<boolean>(false);
  const [isSubscriptionModalOpen, setIsSubscriptionModalOpen] = useState<boolean>(false);

  const refreshShops = useCallback(async () => {
    if (!isAuthenticated) {
      setShops([]);
      setCurrentShopState(null);
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      const res = await apiRequest<Shop[]>("/shops");
      if (res.success && Array.isArray(res.data)) {
        const fetchedShops = res.data;
        setShops(fetchedShops);

        const savedShopId = localStorage.getItem("mcrm_active_shop_id");
        let active = fetchedShops.find((s) => s.id === savedShopId);

        if (!active && fetchedShops.length > 0) {
          active = fetchedShops[0];
        }

        if (active) {
          localStorage.setItem("mcrm_active_shop_id", active.id);
          setCurrentShopState(active);
        } else {
          setCurrentShopState(null);
        }
      }
    } catch (err) {
      console.error("Failed to load medical shops:", err);
    } finally {
      setIsLoading(false);
    }
  }, [isAuthenticated]);

  useEffect(() => {
    refreshShops();
  }, [refreshShops]);

  const setCurrentShop = (shop: Shop) => {
    localStorage.setItem("mcrm_active_shop_id", shop.id);
    setCurrentShopState(shop);
    // Trigger custom event or window reload if deep components cache data
    window.dispatchEvent(new CustomEvent("mcrm_shop_changed", { detail: shop }));
  };

  return (
    <ShopContext.Provider
      value={{
        shops,
        currentShop,
        isLoading,
        setCurrentShop,
        refreshShops,
        isOnboardModalOpen,
        setIsOnboardModalOpen,
        isSubscriptionModalOpen,
        setIsSubscriptionModalOpen,
      }}
    >
      {children}
    </ShopContext.Provider>
  );
};

export const useShop = (): ShopContextType => {
  const context = useContext(ShopContext);
  if (!context) {
    throw new Error("useShop must be used within a ShopProvider");
  }
  return context;
};
