import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const DiamondModule = buildModule('DiamondModule', (m) => {
  const diamondInit = m.contract('DiamondInit');

  return { diamondInit };
});

export default DiamondModule;
